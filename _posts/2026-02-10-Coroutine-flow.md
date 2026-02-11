---
title: "[Kotlin] Coroutine : Flow "
categories:
- Coroutines
tags:
- Study

toc: true
toc_sticky: true
toc_label: 목차
---

코루틴의 `Flow`는 어원인 흐름에서 유추 가능하듯이 물이 흐르는 파이프나 시냇물 처럼 데이터가 흐르는 통로를 만들어 줍니다. 즉, 연속적인 데이터를 요청하여 응답 받아야 하는 경우 사용할 수 있는데요. 1회성 데이터를 요청하는 경우에는 적합하지 않습니다. 보통 **반응형 데이터 스트림**을 만들어 데이터의 변경 사항을 구독하고, 즉시 수집된 새로운 데이터로 UI 를 업데이트 하는 구조로 사용됩니다.

# Flow

`Flow` 는 기본적으로 **발행자** 와 **구독자들** 간의 '방출' 과 '수집' 패턴으로 동작하며, 내부적으로는 람다를 실행하는 원리로 동작합니다.

```kotlin
public interface Flow<out T> {  
	public suspend fun collect(collector: FlowCollector<T>)  
}

public fun interface FlowCollector<in T> {  
	public suspend fun emit(value: T)  
}
```

`Flow` 는 단순한 `collect()` 함수를 가지는 interface 입니다. `Flow` 의 `collect()` 는 `FlowCollector` 를 인자로 받습니다. `FlowCollector<in T>` 는 `emit()` 이라는 함수를 가지는 fun interface 입니다. 이 부분만 보아도, 람다로 치환 가능한 `FlowCollector` 를 `Flow#collect(collector: FlowCollector)` 인자로 넘김으로써 동작한다는 것을 유추할 수 있습니다.

일반적으로 `Flow` 를 생성하기 위해서 빌더 함수인 `flow {}` 를 이용합니다.

```kotlin
public fun <T> flow(@BuilderInference block: suspend FlowCollector<T>.() -> Unit): Flow<T> = SafeFlow(block)  
  
private class SafeFlow<T>(private val block: suspend FlowCollector<T>.() -> Unit) : AbstractFlow<T>() {  
    override suspend fun collectSafely(collector: FlowCollector<T>) {  
        collector.block()  
    }  
}

@ExperimentalCoroutinesApi  
public abstract class AbstractFlow<T> : Flow<T>, CancellableFlow<T> {  
  
    public final override suspend fun collect(collector: FlowCollector<T>) {  
        val safeCollector = SafeCollector(collector, coroutineContext)  
        try {  
            collectSafely(safeCollector)  
        } finally {  
            safeCollector.releaseIntercepted()  
        }  
    }  
  
    public abstract suspend fun collectSafely(collector: FlowCollector<T>)  
}
```

`flow {}` 빌더 함수는 `SafeFlow<T>` 인스턴스를 생성하여 반환하는 단순한 빌더 함수 입니다. 그리고 `collect()` 실행이 `SafeFlow<T>` 의 `collectSafely()` 위임함으로써 중간 연산자들에서 발생할 수 있는 `Coroutine Context` 불일치 문제나 State Machine 의 폭발적 생성을 방지해주기 위해 Context Preservation 과 State Machine Caching 을 통한 성능 최적화를 수행해 줍니다. 자세한 내용은 주석에 잘 정리되어 있습니다.

저의 경우 이렇게 내부구조만 봐서는 람다식이 도대체 어떻게 실행되는 건지 머릿속으로 잘 구조화 되지 않았었습니다. 그래서 단계적으로 어떤 구조로 실행되는지 살펴보겠습니다.

```kotlin
fun interface FlowCollector<in T> {
	suspend fun emit(value: T)
}

interface Flow<out T> {
	suspend fun collect(collector: FlowCollector<T>)
}

int main() {
	val flow = flow { }
}
```

`Flow` Builder 함수는 Flow 의 인스턴스를 생성하여 반환합니다. 그리고 Flow 의 인스턴스는 반드시 `collect()` 중단 함수를 구현해야 합니다. Builder 함수를 더 이해를 돕기 위해 `Flow` 인스턴스의 구현으로 바꿔보겠습니다.

```kotlin
int main() {
	val flow = object: Flow<T> {
		override suspend fun collect(collector: FlowCollector<T>) {
			collector.emit(T)
		}
	}
}
```

`collect` 함수는 인자로 전달 받는 collector 의 `emit()` 중단 함수를 실행하여, 값을 **방출** 할 수 있습니다. 아까 `Flow` 는 발행자와 구독자들 간의 관계 내에서 방출 및 수집 패턴을 통해 동작한다고 언급했습니다. 그렇다면, 방출한 데이터를 수집하기 위해서는 `flow` 인스턴스의 `collect()` 를 호출하면 됩니다.

```kotlin
int main() {
	val flow = object: Flow<T> {
		override suspend fun collect(collector: FlowCollector<T>) {
			collector.emit(T)
		}
	}

	val collector = object: FlowCollector<T> {
		override suspend fun emit(value: T) {
		
		} 
	}

	flow.collect(collector)
}
```

그리고 `collect()` 함수 인자로 전달할 `FlowCollector` 인스턴스를 마찬가지로 생성하여 전달하면, 마침내 `Flow` 의 Builder 함수의 내부를 단순하게(사실은 더 복잡한 과정을 거치지만) 만들어 볼 수 있습니다. 여기서 추가로 함수형 인터페이스는 람다식으로 치환 가능하기 때문에 좀 더 단순하게 만들어 보겠습니다.

```kotlin
int main() {
	val flow = object: Flow<T> {
		override suspend fun collect(collector: FlowCollector<T>) {
			collector.emit(T)
		}
	}

	flow.collect { value ->
		
	}
}
```

여기서 `Flow` 인스턴스를 생성하기 위해 Builder 함수로 바꾸면, 우리가 이미 잘 알고 있는 형태로 바뀌게 됩니다.

```kotlin
int main() {
	val flow = flow<T> {
		emit(T)
	}

	flow.collect { value ->
		
	}
}
```

결과적으로 `Flow<T>` 인스턴스 의 `collect()` 함수 실행은 `flow {}` 빌더 함수 내부에서 방출(emit)  된 값을 수집(collect) 하기 위한 `FlowCollector` 수집기를 등록하는 패턴이 됩니다. 그리고 이것은 복잡한 고차 함수를 활용한 형태로 구조화 되고 있습니다.

그리고 이 과정에서 중요한 점은 `collect()` 함수가 중단 함수이며, `Continuation` 을 생성한다는 점과 `flow {}` Builder 함수가 내부적으로 `SafeFlow` 인스턴스를 사용한다는 점입니다. `collect()` 중단 함수를 실행하기 위해서는 `Coroutine Context` 를 제공하는 `CoroutineScope` 이 반드시 필요하며, 이 때 제공된 `CoroutineContext` 와 실제로 값을 발행(emit) 하는 `emit()` 중단 함수가 실행될 때 사용되는 `Coroutine Context` 가 일치해야만 합니다. 이것을 검증하고 안전하게 관리해주는 인스턴스가 바로 `SafeFlow` 입니다.

하지만 이와 달리, 수집기와 방출기의 `Coroutine Context` 가 다르도록 만들어야 하는 상황도 존재합니다. 즉, 서로 다른 `Coroutine`들 간에 데이터를 요청 및 응답하는 상황이 필요할 수 있습니다. 이에 대한 `Flow` 에서의 구체적 예시가 `callbackFlow()`, `buffer()`, `flowOn()` 등이 있고, 이들은 `Channel` 을 내부적으로 활용합니다.

정리하자면 `Flow` 는 방출기(Emitter) 와 수집기(Collector) 의 실행 `Coroutine Context` 를 다르게 만들어야 하는 상황에서 `Channel` 을 활용하기 때문에, 이를 아는 것 역시 중요합니다.

# Channel

과거 `Kotlinx.Coroutines` 에서는 코루틴간에 통신을 위해서 `Channel` 을 제공하고 있었습니다. `Channel`은 생산자 & 소비자 구조로 동작합니다. 생산자가 데이터를 만들어 `Channel`에 **전송(send)**하면, 소비자가 `Channel`에 있는 데이터를 **수신(receive)**할 수 있는 구조입니다.

채널은 interface이며, 데이터를 전송하기 위한 `SendChannel`과 데이터를 수신하기 위한 `ReceiveChannel` 인터페이스를 구현하고 있습니다.

```kotlin
public interface Channel<E> : SendChannel<E>, ReceiveChannel<E> {
    public companion object Factory {

				/**
				 Channel 의 Type 을 나타냅니다. Type 에 따라, Channel 이 가지는 특성이 달라집니다.
				*/
        public const val UNLIMITED: Int = Int.MAX_VALUE
        public const val RENDEZVOUS: Int = 0
        public const val CONFLATED: Int = -1
        public const val BUFFERED: Int = -2
    }
}

public interface SendChannel<in E> {
    public suspend fun send(element: E)
}

public interface ReceiveChannel<out E> {
    public suspend fun receive(): E
}
```

`Channel`의 생산자와 소비자는 다:다 관계이며, 그 수에 제한이 없습니다. 중요한 동작은 `Channel`이 FIFO 구조로 동작한다는 점입니다. 항상 `Channel` 내부의 Queue 에서 가장 앞에 있는 소비자 순서대로 값을 수신할 수 있습니다. 따라서, 동일한 값에 대해 모든 소비자들이 같은 값을 수신할 수 없습니다.

이런 구조를 `Fan-Out` 이라고 하는데, Coroutine 은 `Fan-out` 뿐만 아니라 `Fan-in` 모두 지원합니다.

## Fan-In / Fan-Out

`Fan-out` 은 `생산자 : 소비자` 가 `1:N` 인 경우를 말합니다. 보통, 값을 생산하는 속도보다 값을 수신하여 처리하는 속도가 느린 경우에 사용합니다. N개의 소비자가 생산된 값을 병렬로 수신 및 처리함으로써 좀 더 나은 성능으로 최적화 할 수 있습니다. 

이와 달리 `Fan-in` 은 `생산자 : 소비자` 가 `N:1` 인 경우를 말합니다. `Fan-out`과 반대로, 값을 수신하여 처리하는 속도보다 값을 생산하는 속도가 느린 경우에 사용합니다. N개의 생산자가 병렬로 값을 생산하면, 생산된 값들을 하나의 소비자가 처리함으로써 좀 더 나은 성능으로 최적화 할 수 있습니다.

동작 구조 상 내부에 `대기 큐` 가 존재하고, `Channel` 의 버퍼에 값이 존재하지 않는 경우 소비자들이 FIFO 구조로 대기하게 됩니다. 값이 존재하는 경우에는 가장 먼저 수신을 요청한 소비자 순서대로 값을 버퍼에서 가져갑니다.

유의할 점은 소비자 코루틴들의 처리 속도가 다른 경우, 값이 뒤섞일 수 있다는 것 입니다. 만약, 생산된 값이 순서를 유지해야 한다면, sequence number 를 값에 포함하거나 별도의 순서 유지를 위한 작업을 수행해야 합니다.

## Channel Type

앞서 본 바와 같이, `SendChannel#send()` 와 `ReceiveChannel#receive()` 은 모두 suspend 함수 입니다. 데이터를 채널로 송신할 때 채널이 가득차 있거나, 데이터를 수신하려고 할 때 채널이 비어있는 경우 suspend 됩니다.

또한, `Channel` 은 내부적으로 `BUFFER` 를 운용합니다. 생산자로 부터 생산된 값은 Buffer 에 순서대로 쌓이게 되며, 이것을 소비자가 소비할 수 있습니다. 

이 두가지 특성의 `Channel()` 의 팩토리 함수 인자에 따라 4가지의 type 을 생성할 수 있습니다. 이들은 **버퍼 공간의 크기**와 버퍼가 **가득 찼을 때 데이터를 어떻게 처리할 것(Overflow 전략)** 인지 에 따라 분류됩니다.

1. UNLIMITED: 채널의 버퍼의 크기가 **무제한**이어서 `SendChannel#send()` 가 중단되지 않습니다.
2. RENDEZVOUS: 채널 버퍼의 크기가 **0**이고, **생산자와 소비자가 모두 데이터를 송신 및 수신**하고 있을 때만 데이터를 교환할 수 있습니다. 그렇지 않다면, 중단됩니다.
3. CONFLATED: 채널의 버퍼의 크기가 **1**이고, 버퍼가 가득 찼을 때 가장 **최신의 것을 유지(drop_oldest)**합니다.
4. BUFFERED: 채널의 버퍼의 크기가 특정 수 만큼을 가집니다. 기본값으로 64 가 지정됩니다.

`Channel` 을 이용하기 위해서는 `Channel()`Factory 함수를 사용하면 됩니다.

```kotlin
public fun <E> Channel(  
    capacity: Int = RENDEZVOUS,  
    onBufferOverflow: BufferOverflow = BufferOverflow.SUSPEND,  
    onUndeliveredElement: ((E) -> Unit)? = null  
): Channel<E> =  
    when (capacity) {  
        RENDEZVOUS -> {  
            if (onBufferOverflow == BufferOverflow.SUSPEND)  
                BufferedChannel(RENDEZVOUS, onUndeliveredElement)
  else  
  ConflatedBufferedChannel(1, onBufferOverflow, onUndeliveredElement)
  }  
        CONFLATED -> {  
            require(onBufferOverflow == BufferOverflow.SUSPEND) {  
  "CONFLATED capacity cannot be used with non-default onBufferOverflow"  
  }  
  ConflatedBufferedChannel(1, BufferOverflow.DROP_OLDEST, onUndeliveredElement)  
        }  
        UNLIMITED -> BufferedChannel(UNLIMITED, onUndeliveredElement)
  BUFFERED -> { 
  if (onBufferOverflow == BufferOverflow.SUSPEND) BufferedChannel(CHANNEL_DEFAULT_CAPACITY, onUndeliveredElement)  
            else ConflatedBufferedChannel(1, onBufferOverflow, onUndeliveredElement)  
        }  
        else -> {  
            if (onBufferOverflow === BufferOverflow.SUSPEND) BufferedChannel(capacity, onUndeliveredElement)  
            else ConflatedBufferedChannel(capacity, onBufferOverflow, onUndeliveredElement)  
        }  
    }
```

`Channel()` 팩토리 함수의 인자로 capacity 와 onBufferOverFlow 를 전달합니다. capacity 에 해당하는 Channel 의 type 이 각각 `RENDEZVOUS`, `BUFFERED` 이면서 onBufferOverFlow 이 `SUSPEND` 라면, 최적화된 인스턴스를 반환합니다. 

그렇지 않은 경우,  `UNLIMITED` 를 제외하고(버퍼 크기 제약이 없으므로) `ConflatedBufferedChannel` 인스턴스를 생성하는데요. 이 인스턴스는 `drop_oldest` 와 `drop_latest` overflow 전략을 지원해주기 위한 클래스입니다. 뭔가 팩토리 함수의 입력만 봤을 때는 Channel 의 type 과 overflow 전략이 무관해 보이지만, 실상 내부를 보면 type 에 따라 동작한다는 점을 볼 수 있습니다.

정리하면, 코루틴이 데이터를 송신 & 수신 할 수 있는 채널에는 `Buffer`가 있고 버퍼의 Overflow 발생 시 `onBufferOverFlow` 전략도 가지고 있습니다. 생산자는 소비자가 없어도 채널로 데이터를 보낼 수 있고, 채널은 Buffer 공간에 쌓아뒀다가 소비자가 수신을 하려 할 때 버퍼에 쌓인 데이터를 전달할 수도 있습니다.

이제 `Channel` 을 `Flow` 에서 어떻게 활용하고 있는지 살펴보겠습니다.

# Flow 의 Channel 활용 사례

`FlowCollector` 수집기를 이용하여 결과 값을 수집할 수 있는 **최종 연산자**가 호출될 때 까지, upStream 의 `Flow` 는 값을 방출하지 않습니다. 이러한 함수형 특징을 기반으로 여러 **중간 연산자**를 활용하여 데이터 스트림에 파이프를 구축하고, 값을 변화시키거나 또는 값을 더 이상 방출되지 않도록 만들 수도 있습니다.

앞서, 일반적으로 **최종 연산자** 가 실행되는 `Coroutine Context` 와 방출기의 `Coroutine Context` 가 일치하도록 Context Preservation  을 수행한다고 언급했었습니다. 해당 동작은 `SafeFlow` 인스턴스에서 구현하고 있고, 그렇다고 모든 중간 연산자들이 그러한 구조를 따르는 것은 아닙니다.

특히, `flowOn()` 과 같은 중간 연산자는 오히려 upStream 의 실행 `Coroutine Context` 를 다르게 하기 위해서 사용할 수 있습니다.

```kotlin
public fun <T> Flow<T>.flowOn(context: CoroutineContext): Flow<T> {  
    checkFlowContext(context) // Context 가 Job 을 포함하면 예외를 던집니다.
    return when {  
        context == EmptyCoroutineContext -> this  // context 가 EmptyCoroutineContext 이면 무시됩니다.
 this is FusibleFlow -> fuse(context = context)  
        else -> ChannelFlowOperatorImpl(this, context = context)  
    }  
}
```

눈여겨 봐야 할 부분은 `FusibleFlow` 입니다. `FusibleFlow` 는 간단하게 `FusibleFlow` 를 구현하는 중간 연산자들이 인접하는 경우 하나의 `Channel` 로 병합하기 위한 `fuse()` 함수를 가진 인터페이스 입니다.

## FusibleFlow

```kotlin
public interface FusibleFlow<T> : Flow<T> {  
  public fun fuse(  
        context: CoroutineContext = EmptyCoroutineContext,  
        capacity: Int = Channel.OPTIONAL_CHANNEL,  
        onBufferOverflow: BufferOverflow = BufferOverflow.SUSPEND  
  ): Flow<T>  
}
```

`Channel` 을 생성하는 중간 연산자들이 연속적으로 사용될 때, 불 필요하게 리소스를 많이 필요로 하는 `Channel` 을 생성하는 것은 바람직하지 않습니다. 따라서, 해당 상황을 최적화 하기 위해 인접하는 경우 몇가지 규칙에 따라 최적화 하게 됩니다. `FusibleFlow` 를 구현하는 인스턴스에 따라 다르지만, `flowOn` 의 경우 연속적으로 사용하더라도, 가장 먼저 호출된 `flowOn` 외에는 모두 무시되도록 최적화 됩니다.

`flowOn` 은 upStream 의 실행 `Coroutine Context` 를 다르게 하기 위해서 사용할 수 있지만, `Channel` 의 capacity 나 onBufferOverFlow 전략은 변경할 수 없고 기본값만 사용이 가능합니다.(기본값은 BUFFERED type 입니다.) 만약, capacity 또는 onBufferOverFlow 를 바꾸고 싶다면 `buffer()` 를 사용할 수 있습니다.

```kotlin
public fun <T> Flow<T>.buffer(capacity: Int = BUFFERED, onBufferOverflow: BufferOverflow = BufferOverflow.SUSPEND): Flow<T> {  
    require(capacity >= 0 || capacity == BUFFERED || capacity == CONFLATED) {  
  "Buffer size should be non-negative, BUFFERED, or CONFLATED, but was $capacity"  
  }  
  require(capacity != CONFLATED || onBufferOverflow == BufferOverflow.SUSPEND) {  
  "CONFLATED capacity cannot be used with non-default onBufferOverflow"  
  }  
  // desugar CONFLATED capacity to (0, DROP_OLDEST)  
  var capacity = capacity  
    var onBufferOverflow = onBufferOverflow  
    if (capacity == CONFLATED) {  
        capacity = 0  
  onBufferOverflow = BufferOverflow.DROP_OLDEST  
  }  
    // create a flow  
  return when (this) {  
        is FusibleFlow -> fuse(capacity = capacity, onBufferOverflow = onBufferOverflow)  
        else -> ChannelFlowOperatorImpl(this, capacity = capacity, onBufferOverflow = onBufferOverflow)  
    }  
}
```

`buffer()` 가 중간 연산자들 중에서 인접한 `FusibleFlow` 인 경우, 같은 `buffer()` 들에 대해서 특정 규칙에 따라 같은 방식으로 병합됩니다.

1. onBufferOverFlow == suspend 이고, capacity 가 BUFFERED 인 경우, 병합된 Channel 은 합계만큼의 크기를 capacity 로 갖습니다.
2. onBufferOverFlow != suspend 라면, 앞선 `buffer()` 들은 모두 무시되며 병합된 Channel 은 해당 `buffer()` 의 인자로 전달된 capacity 의 크기와 onBufferOverFlow 를 따르게 됩니다.

만약, `FusibleFlow` 들이 인접하지 않는다면 인접한 `FusibleFlow` 들만 함께 병합되고, 나머지는 새로운 `Channel` 을 같은 방식으로 병합 된다는 점을 유의해 주세요.

`FusibleFlow` 를 구현하는 `Flow` 들도 다른 중간 연산자들과 마찬가지로 upStream 의 `Flow` 를 해당 `Flow` 에서 수집(collect) 한 뒤에, 함수의 특정 목적을 실현한 새로운 `Flow` 인스턴스를 생성하여 반환하는 것은 구조적으로 동일합니다.

```kotlin
public inline fun <T, R> Flow<T>.transform(  
    @BuilderInference crossinline transform: suspend FlowCollector<R>.(value: T) -> Unit  
): Flow<R> = flow { 
  collect { value ->  
  return@collect transform(value)  
    }  
}
```

아마 확실하지는 않지만 모든 중간 연산자들은 위와 같은 방식으로 동작할 것임이 분명합니다.(물론 모든 중간 연산자 들을 열어본 것은 아닙니다..)

재밌는 점은 중간 연산자들 외에도 `StateFlow` 역시 `FusibleFlow` 를 구현한다는 것 입니다.

## StateFlow: FusibleFlow

```kotlin
private class StateFlowImpl<T>(  
    initialState: Any // T | NULL  
) : AbstractSharedFlow<StateFlowSlot>(), MutableStateFlow<T>, CancellableFlow<T>, FusibleFlow<T> {  
    private val _state = atomic(initialState) // T | NULL  
	  private var sequence = 0 // serializes updates, value update is in process when sequence is odd  
  
	  public override var value: T  
	  get() = NULL.unbox(_state.value)  
	        set(value) { updateState(null, value ?: NULL) }

		override fun tryEmit(value: T): Boolean {  
		    this.value = value  
		    return true  
		}  
  
		override suspend fun emit(value: T) {  
		    this.value = value  
		}
}
```

`StateFlow` 는 일반적인 `Cold Flow` 와 달리 구독자의 수집기(Collector) 와 값의 방출기(Emitter) 의 실행 `Coroutine Context` 가 같을 필요가 없습니다. `StateFlow` 는 내부적으로 thread-safe 한 동시성 자료 구조에 가깝기 때문에 값을 방출할 때도 suspend 할 필요가 없습니다.

`tryEmit()` 과 `emit()` 모두 단순히 `this.value = value` 로써, 내부의 상태값을 의미하는 value 프로퍼티를 update 할 뿐입니다. 즉, 상위 계약 수준을 이행해야만 한다는 LSP 를 만족하기 위해 `emit()`이 suspend 함수이긴 하지만, suspend 해야만 하는 구현은 아닙니다. 따라서 굳이 `emit()` 을 사용하지 않고, `tryEmit()` 을 사용해도 문제가 없습니다. 다만, 수집기에서 `StateFlow` 를 수집(collect) 하는 경우에는 새로운 값이 방출(emit) 될 때 까지, 수집기가 중단되어야 하기 때문에 suspend 가 되어야 합니다.

`StateFlow` 는 단순히 가장 최신 의 값을 `value` 프로퍼티로 유지하는(CONFLATED) 동시성 자료 구조 이기 때문에 이를 위해 실행 `Coroutine Context` 가 반드시 필요한 구조가 아닙니다. 근데 만약 `StateFlow` 에 대한 이해도가 부족했거나, 실수로 인해 `flowOn()` 과 같은 `FusibleFlow` 를 구현하는 중간 연산자를 붙일 경우 `Channel` 을 굳이 만들 이유가 없는데 만들어야만 할 것 입니다.

```kotlin
viewModel.uiState.flowOn(Dispatchers.Main)
```

이런 경우를 위해 `StateFlow` 는 `FusibleFlow` 를 구현함으로써 병합 과정에 무시하도록 구현됩니다.

```kotlin
internal fun <T> StateFlow<T>.fuseStateFlow(  
    context: CoroutineContext,  
    capacity: Int,  
    onBufferOverflow: BufferOverflow  
): Flow<T> {  
    // state flow is always conflated so additional conflation does not have any effect  
  assert { capacity != Channel.CONFLATED } // should be desugared by callers  
  if ((capacity in 0..1 || capacity == Channel.BUFFERED) && onBufferOverflow == BufferOverflow.DROP_OLDEST) {  
        return this  
  }  
    return fuseSharedFlow(context, capacity, onBufferOverflow)  
}
```

다시 돌아와서, `Channel` 은 코루틴이 데이터를 언제 송신하고, 언제 수신할지 모르기 때문에 항상 활성화(Active) 된 상태를 유지해야 합니다. `Channel` 을 모두 사용했지만, `close()` 해주지 않는다면 지속적으로 메모리에 남아있는 문제가 발생합니다. 이러한 매커니즘은 개발자의 '실수' 를 유발할 가능성이 크기 때문에, 이러한 문제들을 보완해주기 위해 제공되는 `produce<T>()` 함수나 `for(i in Channel)` 를 사용해야 합니다.

보통 `Data Layer` 에서 데이터를 요청 하고, 응답을 받는 `Data Logic` 은 요청한 데이터를 모두 응답 받은 상황에서 더 이상 활성화 될 필요가 없습니다. 이런 상황에서 `Channel` 을 활용하는 것은 비효율적입니다. `Channel` 은 지속적으로 활성화된 상태를 유지해야 하는 `Hot Stream` 이 필요할 때 사용하는 것이 좋습니다. 데이터를 한번 요청하고, 연속적인 데이터들을 모두 수신한 후에 종료되는 **1회성 요청** 상황에서는 `Channel` 이 오버엔지니어링 에 가깝게 됩니다. 

이러한 `Data Logic` 을 사용하는 **1회성 데이터 요청** 으로 연속적인 데이터를 응답 받아야 할 때는 `Cold Stream` 인 `Flow` 를 이용해야 합니다.


# Cold Flow vs Hot Flow

플로우는 기본적으로 Cold 합니다. 이런 특징은 Java 의 Stream 이나, Kotlin 의 Sequence 에서도 볼 수 있습니다. 

```kotlin
sequenceOf(1,2,3,4)
    .map { i ->
        println("m$i")
        i
    }.filter { i ->
        println("f$i")
        i % 2 == 0
    }.toList()

결과: m1 f1 m2 f2 m3 f3 m4 f4
```

sequence 는 toList(),  sum() 과 같은 최종 연산이 수행될 때 한 원소에 대해 모든 중간연산과 최종연산을 수행하는 방식으로 실행됩니다. 

이렇듯 Cold Flow 에서도 값을 방출(emit) 한 뒤 수행되는 중간 연산(map, filter 등)은 지연된 후 collect 와 같은 최종연산자에서 모든 연산들이 실행된 결과를 반환 받을 수 있습니다. 이런 특징으로 Data Layer 에서 데이터를 비동기적으로 요청하는 데이터 로직을 처리할 때 사용합니다.

반면에, UI 에 표현되는 데이터가 변경되고, 변경된 데이터를 UI에 update 해주어야 하는 상황에서는 변화하는 데이터 스트림에 실시간으로 반응해 주어야 합니다. 이러한 과정을 수행하기 위해서는 1회성으로 데이터를 요청하는 `Cold Flow` 를 활용할 수 없습니다.물론 Jetpack Room 이나 DataStore 에서는 `Flow` 를 지원하여 반환 타입으로 사용하는 경우, 해당 `Flow` 의 Coroutine 이 `Completion` 되지 않고 무한히 반복문을 통해 변경 사항을 감지하여 데이터를 발행합니다. 

하지만, 안드로이드와 같은 클라이언트 환경에서는 `Lifecycle` 이 존재하고, 변화에 따라 `Flow` 가 `Completion` 되어야 하는 요구 사항이 발생하기 때문에 이를 UI 에서 구독하는 것은 **메모리 누수** 와 같은 심각한 문제가 발생할 수도 있으며, 프로세스가 `BackStack` 에서 제거되지 않음으로 인해 불 필요하게 **메모리를 점유**하는 문제가 발생할 수 있어 지양해야 하는 방법 입니다.

이런 상황을 위해서는 실시간으로 활성화(Active) 되어 있어야 하며, Android 의 `Lifecycle` 에 반응하는 방식(`repeatOnLifecycle` 또는 `collectAsStateWithLifecycle`) 으로 `StateFlow` 를 사용해야만 합니다. 경우에 따라서 이벤트와 같은 현재 상태값이 필요하지 않는 경우에는 `SharedFlow` 를 활용할 수도 있습니다.

`Hot Flow` 는 `Channel`처럼 `collect()` 와 같은 최종 연산이 없어도 활성화 되어 있습니다. 따라서, 언제든지 값이 방출(emit) 되면 replyCache 만큼 최신의 데이터를 가지고 있다가 구독자가 수집(collect)하는 시점에 데이터를 소비할 수 있습니다. 반면에, `Channel` 이 capacity 의 타입에 따라 공간이 가득 찼을 때 onBufferOverFlow 전략으로 관리되는 것과 달리 구독을 시작한 뒤로 준비하는 기간 동안 받지 못한 데이터를 extraBufferCapacity 만큼 오버플로우 전략에 따라 관리하면서 들고 있을 수 있습니다.(물론 StateFlow 와 SharedFlow 는 차이가 있습니다.) 또한, `생산자:소비자` 구조로 동작하는 `Channel` 과 달리 `Flow` 의 특성을 갖는 `Hot Flow` 는 `발행자:구독자` 간의 관계를 갖는 다는 차이점이 존재합니다.