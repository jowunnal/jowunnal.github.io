---
title: "[Kotlin] Coroutine - 예외처리"
categories:
- Coroutines
tags:
- Study

toc: true
toc_sticky: true
toc_label: 목차
---
코루틴을 생성하기 위해서는 간단하게 Coroutine Builder 함수인 launch() 와 async() 를 이용하여 새로운 코루틴을 생성할 수 있습니다. 코루틴 빌더는 CoroutineScope 의 확장함수로써 기본적으로 상위 CoroutineScope 의 CoroutineContext 를 상속하여 구조화된 동시성을 제공합니다. 뿐만 아니라, Coroutine Builder 로 생성되는 코루틴은  자체적으로 CoroutineScope 를 구현합니다. 그리고 매개변수로 전달받는 CoroutineContext 와 상위 Context 를 결합하여 자신의 Context 로 override 하여, 이를 기반으로 자식 코루틴의 실행 context 을 전달합니다.

또한, Coroutine Scope 함수인 coroutineScope() 또는 withContext() 등을 이용하여 새로운 코루틴을 생성할 수도 있습니다. 코루틴 스쿠프 함수는 코루틴 빌더와는 달리 CoroutineScope 의 확장함수가 아니기 때문에 코루틴 빌더와 같은 방법으로 상위의 CoroutineContext 를 상속받을 수 없습니다. 하지만, 중단 함수이기 때문에 호출자로 부터 continuation 을 전달받아 continuation#coroutineContext 를 이용하여 구조화된 동시성을 제공합니다.

구조화된 동시성은 코루틴을 부모-자식 간 관계를 확립하여 예측 가능성을 높이고, 취소나 예외처리를 쉽게 다룰 수 있도록 만들어 줍니다. 특히, 예외 처리를 지원하기 위해 각각의 '코루틴 빌더와 코루틴 스쿠프 함수의 차이점' 을 비교함으로써 각각의 실행 목적이 무엇인지 파악하고, 요구사항에 따라 무엇을 선택해야 하는지에 대해 이번 포스팅에서 정리해 보고자 합니다.

# 코루틴에서의 예외 처리

코루틴을 사용하면서 가장 간단하게 예외를 적재적소로 처리할 수 있는 방법은 예외가 발생할 가능성이 있는 코드 블럭을 try-catch 문이나 runCatching 으로 wrapping 하는 것입니다.

```kotlin
suspend fun main() {
  CoroutineScope(EmptyCoroutineContext) {
    launch {
      try {
        //TODO
      } catch (e: Exception) {}
    }
  }
}
```

하지만 모든 코드블럭에 이와 같은 예외처리를 하는 것은 번거로울 수 있으며, 특히 구조화된 동시성 내에서 부모의 취소에 의해 자식이 취소되는 경우 CancellationException 을 다시 throw 하지 않았을 때, 자식 코루틴이 취소되지 않는 문제 또한 존재합니다.

코루틴에서 발생하는 예외는 구조화된 동시성 내에서 부모로 전파하는 특성을 가지며, 위와 같은 경우 이 특징을 이용하여 공통적이거나 전역적으로 처리될 예외를 최상위 코루틴에 CoroutineExceptionHandler 로 처리할 수 있습니다.

```kotlin
suspend fun main() {
  val exceptionHandler = CoroutineExceptionHandler { //TODO }
  CoroutineScope(EmptyCoroutineContext) {
    launch(exceptionHandler) {
      try {
        //TODO
      } catch (e: Exception) {}
    }
  }
}
```

하지만, 모든 코루틴 빌더에서 CoroutineExceptionHandler 를 설정할 수 있는 것은 아닙니다. 또한, CoroutineExceptionHandler 는 구조화된 동시성 내에서 최상위 코루틴에서만 동작한다는 특징 또한 가집니다. 이러한 동작이 실제로 어떻게 구현되어 있는지 를 이해하고 넘어가야 사용하는 방법을 정확히 알 수 있습니다.

# launch

launch 빌더는 CoroutineContext, CoroutineStart 와 실행할 블록을 매개변수로 전달받고, 내부적으로 StandaloneCoroutine 인스턴스를 생성하여 파라미터로 전달받은 CoroutineStart 의 규칙에 따라 새로운 코루틴을 시작시키고, 해당 코루틴을 handling 할 수 있는 Job 객체를 반환합니다.

```kotlin 
fun CoroutineScope.launch(
    context: CoroutineContext = EmptyCoroutineContext,
    start: CoroutineStart = CoroutineStart.DEFAULT,
    block: suspend CoroutineScope.() -> Unit
): Job {
    val newContext = newCoroutineContext(context)
    val coroutine = if (start.isLazy)
        LazyStandaloneCoroutine(newContext, block) else
        StandaloneCoroutine(newContext, active = true)
    coroutine.start(start, coroutine, block)
    return coroutine
}
```

가장 먼저 보아야 할 부분은 newCoroutineContext() 입니다. 이 함수는 상위 CoroutineScope 의 coroutineContext 에 매개변수로 전달받은 context 를 fold 연산을 하고, Dispatcher 가 없는 경우 Dispatchers.Default 의 기본값을 설정하는 것과 디버그 모드에서 coroutineId 를 추가하여 만들어진 새로운 CoroutineContext 를 반환합니다.

```kotlin
fun CoroutineScope.newCoroutineContext(context: CoroutineContext): CoroutineContext {
    val combined = foldCopies(coroutineContext, context, true)
    val debug = if (DEBUG) combined + CoroutineId(COROUTINE_ID.incrementAndGet()) else combined
    return if (combined !== Dispatchers.Default && combined[ContinuationInterceptor] == null)
        debug + Dispatchers.Default else debug
}
```

foldCopies 함수는 CoroutineContext 에 오버로딩된 '+' 연산자 함수를 이용하여 좌측 coroutineContext(부모)에 우측 coroutineContext(매개변수) 로 덮어써서(override) 결합된 새로운 coroutineContext 를 반환합니다. 내부적으로는CopyableThreadContextElement 타입의 context 에 대해 thread-safe 를 보장해주기 위해 별도의 동작을 처리해 줍니다.

결합된 coroutineContext 를 기반으로 CoroutineStart 가 Lazy 이면 LazyStandaloneCoroutine, 그렇지 않으면 StandaloneCoroutine 인스턴스를 생성하여 코루틴을 시작시킵니다. LazyStandaloneCoroutine 은 StandaloneCoroutine 을 그대로 상속하며, 지연된 상태에서 Job#start 나 Job#join 이 호출될 때 시작 시키기 위한 기능을 캡슐화 하고 있는 클래스 입니다.

```kotlin
private open class StandaloneCoroutine(
    parentContext: CoroutineContext,
    active: Boolean
) : AbstractCoroutine<Unit>(parentContext, initParentJob = true, active = active) {
    override fun handleJobException(exception: Throwable): Boolean {
        handleCoroutineException(context, exception)
        return true
    }
}

private class LazyStandaloneCoroutine(  
    parentContext: CoroutineContext,  
    block: suspend CoroutineScope.() -> Unit  
) : StandaloneCoroutine(parentContext, active = false) {  
    private val continuation = block.createCoroutineUnintercepted(this, this)  
  
    override fun onStart() { // 지연되어 있는 코루틴을 시작시키는 함수
        continuation.startCoroutineCancellable(this)  
    }  
}
```

## JobSupport 의 예외 처리

StandaloneCoroutine 는 AbstractCoroutine 추상 클래스를 상속하며, JobSupport#handleJobException 메소드를 override 하는 클래스 입니다. JobSupport#handleJobException 은 현재의 Job 이 발생한 예외를 처리할 수 있는지 에 대한 여부를 반환하는 함수 입니다. 이 함수는 기본값으로 false 를 리턴하여 예외를 처리할 방법이 없도록 명시하며, StandaloneCoroutine 은 별도로 true 를 리턴하면서 handleCoroutineException() 으로 위임 하도록 override 함으로써 예외를 처리할 방법이 있도록 명시합니다.(이외에도 ActorCoroutine 이 override 합니다.)

```kotlin
public fun handleCoroutineException(context: CoroutineContext, exception: Throwable) {
  try {
    context[CoroutineExceptionHandler]?.let {
      it.handleException(context, exception)
      return
    }
  } catch (t: Throwable) {
    handleCoroutineExceptionImpl(context, handlerException(exception, t))
    return
  }
  handleCoroutineExceptionImpl(context, exception)
}
```

JobSupport#handleCoroutineException() 함수는 coroutineContext 에 CoroutineExceptionHandler 가 설정된 경우 해당 CoroutineExceptionHandler 로 예외를 처리하고, 그렇지 않은 경우 handleCoroutineExceptionImpl() 로 예외 처리를 위임합니다. 이는 최종적으로 ServiceLoader 에서 CoroutineExceptionHandler 들을 가져와 처리할 수 있다면 처리하고 그렇지 않은 경우, 현재 스레드의 Thread#uncaughtExceptionHandler 로 예외를 처리하도록 구현되어 있습니다.

JobSupport#handleJobException() 함수는 코루틴이 완료될 때, JobSupport#finalizeFinishingState() 에서 호출됩니다.

```kotlin
private fun finalizeFinishingState(state: Finishing, proposedUpdate: Any?): Any? {  
  /*
  중략
  */  
  
  if (finalException != null) {  
      val handled = cancelParent(finalException) || handleJobException(finalException)  
      if (handled) (finalState as CompletedExceptionally).makeHandled()  
  }  
  onCompletionInternal(finalState)  
  val casSuccess = _state.compareAndSet(state, finalState.boxIncomplete())  
  assert { casSuccess }  
  completeStateFinalization(state, finalState)  
  return finalState  
}
```

코루틴이 완료될 때, cancelParent() 함수를 호출하여 부모가 있다면 부모에 예외를 전파하면서 부모를 취소시키고 false 를 반환하며, 부모가 처리할 수 없는 경우 true 를 반환하여 JobSupport#handleJobException 을 동작시키지 않습니다. 즉, 코루틴의 예외는 항상 부모가 처리하도록 최대한 위임하며, 부모가 처리할 수 없는 경우 현재의 코루틴이 JobSupport#handleJobException 을 통해 예외를 처리할지 말지 결정하게 됩니다.

```kotlin
private fun cancelParent(cause: Throwable): Boolean {  
  if (isScopedCoroutine) return true  
  
  val isCancellation = cause is CancellationException  
  val parent = parentHandle   
  if (parent === null || parent === NonDisposableHandle) {  
    return isCancellation  
  }  

  return parent.childCancelled(cause) || isCancellation  
}
```

먼저, JobSupport#cancelParent() 는 코루틴 스쿠프 함수로 생성된 ScopedCoroutine 타입의 코루틴 인스턴스라면 true 를 반환합니다. 이 경우 JobSupport#handleJobException 은 호출되지 않아 CoroutineExceptionHandler 로 예외가 처리되지 않고, 단순히 해당 예외를 block 의 결과로 throw 합니다.

그렇지 않고 해당 코루틴이 부모가 없고 취소 예외라면 true, 그렇지 않으면 false 를 반환합니다. 취소 예외 였다면, JobSupport#handleJobException 은 호출되지 않고 단순히 현재 코루틴과 자식들을 취소시킵니다. 그 외의 예외 라면, JobSupport#handleJobException 의 결과에 따라 현재 코루틴이 예외를 처리할 수 있으면 처리하고 그렇지 않으면, 해당 예외를 block 의 결과로 throw 합니다.

scopedCoroutine 도 아니고 부모 코루틴이 존재했다면, 해당 예외를 부모로 전파하면서 취소시키게 됩니다.

cancelParent() 와 finalizeFinishingState() 는 모두 JobSupport 에 구현되어 있고, AbstractCoroutine 이 상속하고 있습니다. 코루틴을 생성하는 launch 나 async 빌더 뿐만 아니라 코루틴 스쿠프 함수를 포함하여 모든 코루틴 클래스는 AbstractCoroutine 를 상속합니다. 그렇기 때문에 AbstractCoroutine 도 살펴볼 필요가 있습니다.

## AbstractCoroutine

AbstractCoroutine 은 JobSupport 외에도 Job, Continuation, CoroutineScope 를 구현하고 있습니다.

```kotlin
public abstract class AbstractCoroutine<in T>(  
    parentContext: CoroutineContext,  
    initParentJob: Boolean,  
    active: Boolean  
) : JobSupport(active), Job, Continuation<T>, CoroutineScope {  
  
    init {  
        if (initParentJob) initParentJob(parentContext[Job])  
    }  

    @Suppress("LeakingThis")  
    public final override val context: CoroutineContext = parentContext + this
}
```

즉, AbstractCoroutine 을 상속하는 StandaloneCoroutine 은 그 자체로 Job 이 되며, launch 함수가 Job 을 반환할 수 있는 이유도 여기서 파생됩니다. 또한, AbstractCoroutine 이 CoroutineScope 를 구현하고 있는 점도 중요합니다.

```kotlin
public interface CoroutineScope {  
    public val coroutineContext: CoroutineContext  
}
```

코루틴 스쿠프는 단순히 coroutineContext 를 프로퍼티로 갖는 인터페이스 입니다. 코루틴 스쿠프는 단순히 코루틴이 실행되기 위한 __영역__ 이라고 생각될 수 있는데, 이 영역 내에서 실행될 코루틴을 위한 환경 정보가 coroutineContext 입니다. 

StandaloneCoroutine 이 CoroutineScope 를 구현하는 AbstractCoroutine 을 상속하고 있고, 다시 돌아가서 launch 함수의 구현을 보면,

```kotlin 
fun CoroutineScope.launch(
    context: CoroutineContext = EmptyCoroutineContext,
    start: CoroutineStart = CoroutineStart.DEFAULT,
    block: suspend CoroutineScope.() -> Unit
): Job {
    val newContext = newCoroutineContext(context)
    val coroutine = if (start.isLazy)
        LazyStandaloneCoroutine(newContext, block) else
        StandaloneCoroutine(newContext, active = true)
    coroutine.start(start, coroutine, block) // 해당 block 은 StandaloneCoroutine 에서 실행됩니다.
    return coroutine
}
```

launch 함수의 파라미터로 받은 block 의 리시버인 CoroutineScope 가 바로 StandaloneCoroutine 인 것입니다. 따라서 해당 launch 함수는 부모의 CoroutineScope 에서 실행되면서 구조화된 동시성이 활성화되며, 생성된 StandaloneCoroutine 내에서 실행될 block 의 코루틴들도 StandaloneCoroutine 의 CoroutineScope 에서 실행되어 구조화된 동시성을 제공할 수 있게 됩니다.

그렇다면 launch 외의 async 나 코루틴 스쿠프 함수들도 모두 launch 처럼 동작할까요? 정답은 '그렇지 않다' 입니다. launch 와 async 의 차이점은 결과값 반환의 유무에서 시작합니다.

# Async

async 빌더 함수의 입력 파라미터와 생성 로직은 launch 와 크게 다르지는 않습니다.

```kotlin
public fun <T> CoroutineScope.async(  
    context: CoroutineContext = EmptyCoroutineContext,  
    start: CoroutineStart = CoroutineStart.DEFAULT,  
    block: suspend CoroutineScope.() -> T  
): Deferred<T> {  
    val newContext = newCoroutineContext(context)  
    val coroutine = if (start.isLazy)  
        LazyDeferredCoroutine(newContext, block) else  
  DeferredCoroutine<T>(newContext, active = true)  
    coroutine.start(start, coroutine, block)  
    return coroutine  
}
```

launch 와 마찬가지로 부모 scope 의 context 에 매개변수로 전달받은 context 를 결합하고, CoroutineStart 가 Lazy 인 경우 LazyDeferredCoroutine 을 생성하거나 그렇지 않은 경우 DeferredCoroutine 인스턴스를 생성한 뒤에 CoroutineStart 에 따라 해당 코루틴을 시작시킵니다.

하지만 launch 와 달리 block 파라미터의 결과가 Unit 이 아닌, 타입 파라미터 T 의 값을 반환하며 빌더 함수의 결과로 Deferred\<T> 를 반환합니다. Deferred\<T> 는 Job 을 구현하여 launch 의 반환과 같이 해당 코루틴을 handling 할 수 있으며, 추가적으로 Deferred#await() 을 이용하여 block 이 반환하는 T 타입의 결과값을 반환할 때 까지 중단 시킬 수 있습니다.

즉, launch 는 코루틴을 생성하고 시작한 뒤에 그 결과가 필요 없는 경우 사용하며, async 는 결과가 필요한 경우 사용한다는 차이점이 있습니다.

```kotlin
private open class DeferredCoroutine<T>(  
    parentContext: CoroutineContext,  
    active: Boolean  
) : AbstractCoroutine<T>(parentContext, true, active = active), Deferred<T> {  
  override fun getCompleted(): T = getCompletedInternal() as T  
  override suspend fun await(): T = awaitInternal() as T  
  override val onAwait: SelectClause1<T> get() = onAwaitInternal as SelectClause1<T>  
}  
  
private class LazyDeferredCoroutine<T>(  
    parentContext: CoroutineContext,  
    block: suspend CoroutineScope.() -> T  
) : DeferredCoroutine<T>(parentContext, active = false) {  
    private val continuation = block.createCoroutineUnintercepted(this, this)  
    override fun onStart() {  
        continuation.startCoroutineCancellable(this)  
    }  
}
```

또한, 앞서 언급한 바와 같이 StandaloneCoroutine 과 달리 DeferredCoroutine 은 JobSupport#handleJobException 을 override 하지 않습니다. 그 이유는 launch 와 달리 async 빌더는 Deferred\<T> 를 반환하고, Deferred#await() 중단 함수로 block 의 결과값이 실제로 반환될 때 예외를 처리해주어야 하기 때문입니다. 

따라서 async 빌더로 생성된 코루틴은 예외를 처리할 수 있는 방법이 없으며, 같은 맥락으로 최상위 코루틴을 async 로 사용하고 CoroutineExceptionHandler 를 context 파라미터로 전달해도 동작하지 않게 됩니다. 이때는 await() 호출을 try-catch 나 runCatching 으로 wrapping 하여 예외를 처리해주어야 합니다.

```kotlin
suspend fun main() {
  runBlocking {
    val result = async { 
      //TODO
    }
    
    try { 
      result.await() // await 호출 부분에서 예외를 처리해 주어야 합니다.
    } catch (e: Exception) {}
  }
}
```

만약, await() 호출을 예외 처리 해주지 않는다면 해당 예외는 상위 코루틴으로 전파시킵니다. 코루틴의 예외는 앞서 살펴 보았듯이 구조화된 동시성 내에서 항상 부모 코루틴으로 전파시키며, 최상위(Root) 코루틴에서 예외를 처리하도록 위임합니다.

코루틴 스쿠프 함수도 마찬가지로 JobSupport#handleJobException() 을 별도로 override 하지 않습니다. 또한 코루틴 스쿠프 함수들은 block 의 결과값을 그대로 반환하기 때문에 해당 함수의 호출 부분에서 별도의 예외를 처리해야 합니다.

# Coroutine Scope Function

기본적인 예시로 coroutineScope() 함수를 살펴보겠습니다.

```kotlin
public suspend fun <R> coroutineScope(block: suspend CoroutineScope.() -> R): R {  
  contract {  
    callsInPlace(block, InvocationKind.EXACTLY_ONCE)  
  }  
  
  return suspendCoroutineUninterceptedOrReturn { uCont ->  
    val coroutine = ScopeCoroutine(uCont.context, uCont)  
    coroutine.startUndispatchedOrReturn(coroutine, block)  
  }  
}
```

코루틴 스쿠프 함수들은 모두 중단 함수이며, 중단 함수의 특징으로 전달 받은 continuation 매개변수의coroutineContext 를 기반으로 새로운 코루틴을 생성하게 됩니다.

```kotlin
internal open class ScopeCoroutine<in T>(  
    context: CoroutineContext,  
    @JvmField val uCont: Continuation<T>
) : AbstractCoroutine<T>(context, true, true), CoroutineStackFrame {  

  final override val callerFrame: CoroutineStackFrame? get() = uCont as? CoroutineStackFrame  
  final override fun getStackTraceElement(): StackTraceElement? = null  
  final override val isScopedCoroutine: Boolean get() = true  
  
  override fun afterCompletion(state: Any?) {  
    uCont.intercepted().resumeCancellableWith(recoverResult(state, uCont))  
  }  
  
  override fun afterResume(state: Any?) {  
    uCont.resumeWith(recoverResult(state, uCont))  
  }  
}
```

그리고 ScopedCoroutine 은 JobSupport#handleJobException() 을 override 하지 않아 해당 코루틴이 예외를 처리할 수도 없으며, isScopedCoroutine 을 true 로 override 함으로써 JobSupport#cancelParent() 에서 결과값을 true 로 반환하도록 만들어 JobSupport#handleJobException() 이 호출되지 않도록 합니다. 

```kotlin
private fun cancelParent(cause: Throwable): Boolean {  
  if (isScopedCoroutine) return true  
  
  /*
  생략
  */ 
}
```

결과적으로는 코루틴 스쿠프 함수의 호출 부분에서 별도로 예외를 처리해야만 합니다.

```kotlin
suspend fun main() {
  runBlocking {
    try { 
      coroutineScope {} // 호출 부분에서 예외가 그대로 throw 됩니다.
    } catch (e: Exception) {}
  }
}
```
