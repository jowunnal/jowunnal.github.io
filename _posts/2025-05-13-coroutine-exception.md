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
  runBlocking { // await() 에 예외를 처리했어도, 부모-자식 관계에 의해 예외는 부모로 전파되어 취소됩니다.
    val result = async { 
      //TODO
    }
    
    try { 
      result.await() // await 호출 부분에서 예외를 처리해 주어야 합니다.
    } catch (e: Exception) {}
  }
}
```

하지만, await() 호출에 예외를 처리해도, 상위 코루틴으로 예외가 전파됩니다. 코루틴의 예외는 앞서 살펴 보았듯이 구조화된 동시성 내에서 항상 부모 코루틴으로 전파시키며, 최상위(Root) 코루틴에서 예외를 처리하도록 위임한다는 점을 유의해야 합니다. 

보통 이런 경우 코루틴 스쿠프 함수를 활용하는 것이 예외를 처리하는데 편리합니다. 코루틴 스쿠프 함수는 block 내에서 발생한 예외를 단순히 호출자에 그대로 던지기 때문에, 코루틴 스쿠프 함수 호출을 try-catch 로 잡아서 처리하면 부모 코루틴에 전파되지는 않습니다.

# Coroutine Scope Function

코루틴 스쿠프 함수도 마찬가지로 JobSupport#handleJobException() 을 별도로 override 하지 않습니다. 기본적인 예시로 coroutineScope() 함수를 살펴보겠습니다.

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
      coroutineScope { throw Exception } // 호출 부분에서 예외가 그대로 throw 됩니다.
    } catch (e: Exception) {}
  }
}
```

# 코루틴 빌더 vs 코루틴 스쿠프 함수

그렇다면 코루틴을 생성하는데 있어서 코루틴 빌더를 사용하는 것과 코루틴 스쿠프 함수를 사용하는 것에 대한 차이점이 뭘까요? 명칭만 봐서는 코루틴 스쿠프를 생성하거나 그렇지 않은 것 처럼 보이지만 앞서 살펴본 내부 구조에서 코루틴 빌더로 생성된 코루틴도 마찬가지로 CoroutineScope 를 구현하는 AbstractCoroutine 을 상속하기 때문에 코루틴 스쿠프를 생성한다는 점에서 코루틴 스쿠프 함수와 동일합니다. .

다만, 구현에 따라 몇가지 차이점이 존재합니다.

## Dispatch 최적화

코루틴 빌더인 launch 나 async 로 생성되는 코루틴은 CoroutineContext 에 등록된 Dispatcher 와 CoroutineStart 의 타입에 따라 스레드를 관리하는 Dispatcher 로 dispatch 과정이 발생할지 말지가 결정됩니다. 보통의 경우로 예시를 들자면, Dispatchers.Default(기본값) 과 CoroutineStart.Default(기본값) 을 사용한다면 해당 코루틴은 항상 dispatch 과정이 동반됩니다. dispatch 과정은 빌더 함수를 호출한 thread 에서 Dispatcher 가 관리중인 스레드로 실행할 task 를 전달하는 과정이 수행되어, 호출자 thread 에서 바로 task 를 실행하는 것 보다 느리다고 주석에 설명되어 있습니다.

하지만, 코루틴 스쿠프 함수는 최대한 dispatch 없이 호출자 thread 에서 바로 task 가 실행되도록 구현되어 있습니다. 물론 모두가 그런것은 아니어서 RunBlocking 의 경우 호출 스레드를 차단하고 Dispatchers.Default 로 실행하기 때문에 dispatch가 발생하고, withContext 의 경우 매개변수로 전달받은 CoroutineContext 에서 호출자(부모)와 다른 Dispatcher 가 포함되어 있다면 해당 Dispatcher 로 dispatch 과정이 일어납니다. 그 외의 coroutineScope, supervisorScope, withTimeOut 함수들은 dispatch 없이 호출자의 Thread 에서 실행됩니다.

### 코루틴 빌더

코루틴 빌더로 생성되는 코루틴을 시작시킬 때, CoroutineStart 값에 따라 다르게 시작된다는 점도 확인했었습니다.

```kotlin
public fun CoroutineScope.launch(  
    context: CoroutineContext = EmptyCoroutineContext,  
    start: CoroutineStart = CoroutineStart.DEFAULT,  
    block: suspend CoroutineScope.() -> Unit  
): Job {  
    val newContext = newCoroutineContext(context)  
    val coroutine = if (start.isLazy)  
        LazyStandaloneCoroutine(newContext, block) else  
        StandaloneCoroutine(newContext, active = true)  
    coroutine.start(start, coroutine, block)  // --> 이부분 입니다.
    return coroutine  
}

public fun <T> CoroutineScope.async(  
    context: CoroutineContext = EmptyCoroutineContext,  
    start: CoroutineStart = CoroutineStart.DEFAULT,  
    block: suspend CoroutineScope.() -> T  
): Deferred<T> {  
    val newContext = newCoroutineContext(context)  
    val coroutine = if (start.isLazy)  
        LazyDeferredCoroutine(newContext, block) else  
        DeferredCoroutine<T>(newContext, active = true)  
    coroutine.start(start, coroutine, block)  // --> 이부분 입니다.
    return coroutine  
}

abstract class AbstractCoroutine { // 다른 부분들은 생략
  public fun <R> start(start: CoroutineStart, receiver: R, block: suspend R.() -> T) {  
      start(block, receiver, this)  
  }
}
```

코루틴을 시작시키기 위해 AbstractCoroutine#start 함수를 호출하는데, StandaloneCoroutine 과 DeferredCoroutine 은 CoroutineStart invoke 연산자 메소드로 위임합니다.

```kotlin
@InternalCoroutinesApi  
public operator fun <R, T> invoke(block: suspend R.() -> T, receiver: R, completion: Continuation<T>): Unit =  
    when (this) {  
        DEFAULT -> block.startCoroutineCancellable(receiver, completion)  
        ATOMIC -> block.startCoroutine(receiver, completion)  
        UNDISPATCHED -> block.startCoroutineUndispatched(receiver, completion)  
        LAZY -> Unit // will start lazily  
  }
```

그리고 결과적으로 해당 코루틴의 실행 block 을 Runnable task 로 만든 후, CoroutineContext 에 등록된 Dispatcher 에 따라 지정된 스레드에서 해당 Runnable 이 실행되게 됩니다. 이 때, Dispatcher 가 Unconfined 가 아닌 경우 반드시 dispatch 과정이 동반되며, 성능적 오버헤드가 발생합니다.(해당 과정의 코드들이 많고 복잡하기 때문에 포스팅에 삽입하지는 못했지만, 직접 찾아보시는걸 권장드립니다.)

### 코루틴 스쿠프 함수

이와 달리, 코루틴 스쿠프 함수들 에서는 dispatch 과정이 일어나지 않고 코루틴 스쿠프 함수를 호출하고 있는 호출자 스레드에서 block 이 최대한 실행되도록 구현됩니다. 대표적 예시로 coroutineScope 를 살펴보자면,

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

internal fun <T, R> ScopeCoroutine<T>.startUndispatchedOrReturn(receiver: R, block: suspend R.() -> T): Any? {  
    return undispatchedResult({ true }) {  
  block.startCoroutineUninterceptedOrReturn(receiver, this)  
    }  
}
```

코루틴을 시작시키는 kotlinx.coroutines.intrinsics 에 정의된 startUndispatchedOrReturn 를 호출하여 dispatch 없이 호출자 thread 에서 그대로 block 을 실행합니다. coroutineScope 와 달리 withContext 의 경우 coroutineContext 가 필수 매개변수 이며, 해당 coroutineContext 의 dispatcher 가 호출자의 dispatcher 와 다르다면, dispatch 를 수행합니다.

```kotlin
public suspend fun <T> withContext(  
    context: CoroutineContext,  
    block: suspend CoroutineScope.() -> T  
): T {  
    contract {  
  callsInPlace(block, InvocationKind.EXACTLY_ONCE)  
    }  
  return suspendCoroutineUninterceptedOrReturn sc@ { uCont ->  
  // compute new context  
  val oldContext = uCont.context  
        // Copy CopyableThreadContextElement if necessary  
  val newContext = oldContext.newCoroutineContext(context)  
        // always check for cancellation of new context  
  newContext.ensureActive()  
        // FAST PATH #1 -- new context is the same as the old one  
  if (newContext === oldContext) {  
            val coroutine = ScopeCoroutine(newContext, uCont)  
            return@sc coroutine.startUndispatchedOrReturn(coroutine, block)  
        }  
        // FAST PATH #2 -- the new dispatcher is the same as the old one (something else changed)  
 // `equals` is used by design (see equals implementation is wrapper context like ExecutorCoroutineDispatcher)  if (newContext[ContinuationInterceptor] == oldContext[ContinuationInterceptor]) {  
            val coroutine = UndispatchedCoroutine(newContext, uCont)  
            // There are changes in the context, so this thread needs to be updated  
  withCoroutineContext(coroutine.context, null) {  
  return@sc coroutine.startUndispatchedOrReturn(coroutine, block)  
            }  
  }  
        // SLOW PATH -- use new dispatcher  
  val coroutine = DispatchedCoroutine(newContext, uCont)  
        block.startCoroutineCancellable(coroutine, coroutine)  
        coroutine.getResult()  
    }  
}
```

이 코드에서는 주석을 제거하지 않고 가져왔습니다. 주석을 살펴보시면, Dispatcher 가 다른 경우 SLOW PATH 라고 명시되어 있고, 그렇지 않은 경우 FAST PATH 라고 되어 있습니다. 해당 주석으로만 봐도 dispatch 과정이 동반되는 것은 그렇지 않은 과정보다 느리다고 판단될 수 있습니다.

이와 달리 RunBlocking 은 호출자 스레드를 단순히 차단하고, Dispatchers.Default 로 코루틴을 시작시킵니다.

```kotlin
@Throws(InterruptedException::class)  
public actual fun <T> runBlocking(context: CoroutineContext, block: suspend CoroutineScope.() -> T): T {  
    /*
    중략
    */  
    val coroutine = BlockingCoroutine<T>(newContext, currentThread, eventLoop)  
    coroutine.start(CoroutineStart.DEFAULT, coroutine, block)  
    return coroutine.joinBlocking()  
}

private class BlockingCoroutine<T>(  
    parentContext: CoroutineContext,  
    private val blockedThread: Thread,  
    private val eventLoop: EventLoop?  
) : AbstractCoroutine<T>(parentContext, true, true) {  
    @Suppress("UNCHECKED_CAST")  
    fun joinBlocking(): T {  
        registerTimeLoopThread()  
        try {  
            eventLoop?.incrementUseCount()  
            try {  
                while (true) {  
                    @Suppress("DEPRECATION")  
                    if (Thread.interrupted()) throw InterruptedException().also { cancelCoroutine(it) }  
  val parkNanos = eventLoop?.processNextEvent() ?: Long.MAX_VALUE  
  if (isCompleted) break  
  parkNanos(this, parkNanos)  
                }  
            } finally { // paranoia  
  eventLoop?.decrementUseCount()  
            }  
        } finally { // paranoia  
  unregisterTimeLoopThread()  
        }  
  val state = this.state.unboxState()  
        (state as? CompletedExceptionally)?.let { throw it.cause }  
  return state as T  
  }  
}
```

#### SupervisorScope

superviserScope 도 마찬가지로 coroutineScope 와 같이 dispatch 없이 호출자 스레드에서 block 을 실행시킵니다. 하지만, superviserScope 는 자식에게 발생한 예외를 부모로 전파하지 않는 조금 다른 특성을 가집니다.

```kotlin
public suspend fun <R> supervisorScope(block: suspend CoroutineScope.() -> R): R {  
    contract {  
      callsInPlace(block, InvocationKind.EXACTLY_ONCE)  
    }  
    return suspendCoroutineUninterceptedOrReturn { uCont ->  
      val coroutine = SupervisorCoroutine(uCont.context, uCont)  
      coroutine.startUndispatchedOrReturn(coroutine, block)  
    }  
}  

private class SupervisorCoroutine<in T>(  
    context: CoroutineContext,  
    uCont: Continuation<T>  
) : ScopeCoroutine<T>(context, uCont) {  
    override fun childCancelled(cause: Throwable): Boolean = false  
}
```

supervisorScope 에서 생성되는 코루틴은 SuperviserCoroutine 클래스의 인스턴스 입니다. 해당 코루틴은 JobSupport#childCancelled 를 false 값을 반환하도록 override 하고 있습니다.

```kotlin
public open class JobSupport constructor(active: Boolean) : Job, ChildJob, ParentJob {
  public open fun childCancelled(cause: Throwable): Boolean {  
    if (cause is CancellationException) return true  
    return cancelImpl(cause) && handlesException  
  }
}
```

JobSupport#childCancelled 는 자식에게 발생한 예외에 대해 부모가 취소될지 말지 그리고 자식의 예외를 처리할지 말지를 결정하는 함수입니다. 반환 값이 true 라면 예외를 처리함과 동시에 취소되며, false 인 경우 예외를 처리하지 않고 부모가 취소되지도 않습니다.

supervisorCoroutine 은 해당 값을 false 를 반환하도록 하여, 자식에 대한 예외를 처리하지 않고, 자식의 예외가 부모인 supervisorCoroutine 을 취소되지 않도록 만듭니다. 따라서 하위 코루틴에서 발생한 예외를 처리 및 전파하지 않아, 다른 형제 코루틴들이 취소되지 않도록 해주지만, 상위 코루틴의 취소는 하위로 그대로 전파하여 취소시키는 특징을 갖습니다.

이러한 구조는 ViewModel 의 ViewModelScope 에서도 사용되고 있습니다. ViewModelScope 은 supervisorScope 을 사용하지는 않지만, supervisorJob 을 CoroutineContext 로 가집니다.

```kotlin

public val ViewModel.viewModelScope: CoroutineScope  
  get() = synchronized(VIEW_MODEL_SCOPE_LOCK) {  
    getCloseable(VIEW_MODEL_SCOPE_KEY)  
       ?: createViewModelScope().also { scope -> addCloseable(VIEW_MODEL_SCOPE_KEY, scope)
    }  
  }
 
internal fun createViewModelScope(): CloseableCoroutineScope {  
  val dispatcher = try {  
     Dispatchers.Main.immediate  
  } catch (_: NotImplementedError) {  
    EmptyCoroutineContext  
  } catch (_: IllegalStateException) {   
    EmptyCoroutineContext  
  }  
  
  return CloseableCoroutineScope(coroutineContext = dispatcher + SupervisorJob())  
}
```

supervisorScope 과 달리 supervisorJob 을 사용하는 것은 구조화된 동시성을 깰 수 있는 문제가 있습니다. viewModelScope 는 CoroutineScope 의 CoroutineContext 로 할당하기 때문에 최상위 코루틴이 supervisorJob 을 부모로 갖게 되어 문제가 없지만, 최상위 코루틴이 아닌 하위 코루틴이나 supervisorScope 이 아닌 코루틴 스쿠프 함수에 할당할 경우 구조화된 동시성이 깨지는 문제가 발생합니다.

```kotlin
suspend fun main() {
  runBlocking {
    launch(SupervisorJob()) {
      delay(500)
      throw IllegalArgumentException("예외")
    }
  }
}
```

위 예시에서 500ms 후에 예외가 발생해야 하지만 예외 발생없이 종료됩니다. 그 이유는 runBlocking() 의 Job 이 자식 코루틴(launch)의 부모가 되어야 하지만, SupervisorJob 이 runBlocking 의 job 을 override 해버리게 되어 부모-자식 간의 관계가 깨져버리기 때문입니다. 따라서, runBlocking 은 자식이 종료될 때 까지 대기해야 하지만 자식이 없는 상태가 되어 그대로 종료되게 됩니다.

이렇듯 최상위 코루틴이 아닌 경우에는 supervisorScope() 함수를 사용하는 것이 더 적절합니다.

#### SupervisorScope 의 예외처리

supervisorScope 의 예외는 다른 코루틴 스쿠프 함수들과 다르게 처리됩니다. 코루틴 스쿠프 함수들은 공통적으로 함수 호출 부분에서 예외를 처리해야 하지만, supervisorScope 은 자식에게 발생한 예외가 SupervisorCoroutine 에서 처리 및 전파되지는 않아 구조화된 동시성 내에서 부모 나 형제 코루틴을 취소시키지는 않지만, 해당 코루틴의 예외는 구조화된 동시성 내에서 부모 코루틴에게 "보고"됩니다.

```kotlin
suspend fun main() {
  runBlocking { // 코루틴이 취소되지는 않지만, IllegalArgumentException 이 발생합니다.
    supervisorScope {
      launch {
        delay(500)
        throw IllegalArgumentException("예외")
      }
    }
  }
}
```

위와 같은 경우에서는 runBlocking 함수 내부에서 생성되는 BlockingCoroutine 이 handleJobException 을 override 하지 않기 때문에 코루틴의 예외를 처리할 수 없는 단점이 있습니다. 이런 경우 최상위 코루틴이 launch 로 시작하도록 만들고 CoroutineExceptionHandler 를 이용하여 처리되지 않은 코루틴의 예외를 최상위에서 잡아주어야 합니다.

```kotlin
suspend fun main() {
  CoroutineScope(Dispatchers.Default).launch (CoroutineExceptionHandler { c, t -> //TODO } { // CoroutineExceptionHandler 에서 처리되지 않은 예외가 최종적으로 처리됩니다.
    supervisorScope {
      launch {
        delay(500)
        throw IllegalArgumentException("예외")
      }
    }
  }
}
```

supervisorScope 하위의 코루틴에서 발생하는 것이 아닌, block 의 실행에서 직접적으로 발생하는 예외는 다른 코루틴 스쿠프 함수들과 같이 함수 호출에서 try-catch 로 예외를 처리하면 됩니다.

```kotlin
suspend fun main() {
  CoroutineScope(Dispatchers.Default).launch {
    try {
      supervisorScope {
        delay(500)
        throw IllegalArgumentException("예외")
      }
    } catch (e: Exception) { //TODO }
  }
}
```

결과적으로 코루틴 빌더와 달리 코루틴 스쿠프 함수는 좀 더 빠른 실행을 위한 dispatch 최적화 과정을 수행하며, 중단 함수로써의 특징을 갖습니다.