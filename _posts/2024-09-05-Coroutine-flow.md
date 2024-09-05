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

코루틴의 플로우는 어원인 흐름에서 유추 가능하듯이 물이 흐르는 파이프나 시냇물 처럼 데이터가 흐르는 통로를 말합니다. 플로우 이전에 Kotlin.Coroutine 에서는 코루틴간에 통신을 위해서 Channel 을 제공하고 있었습니다. 채널은 생산자와 소비자가 있고 생산자가 데이터를 만들어 채널에 보내면(send), 소비자가 채널에 있는 데이터를 받을(receive)수 있는 구조입니다.

# Channel

채널은 인터페이스이며, 데이터를 송신하기 위한 SendChannel 과 데이터를 수신하기 위한 ReceiveChannel 인터페이스를 구현하고 있습니다.

```kotlin
public interface Channel<E> : SendChannel<E>, ReceiveChannel<E> {
    /**
     * Constants for the channel factory function `Channel()`.
     */
    public companion object Factory {

        public const val UNLIMITED: Int = Int.MAX_VALUE

        public const val RENDEZVOUS: Int = 0

        public const val CONFLATED: Int = -1

        public const val BUFFERED: Int = -2

        internal const val OPTIONAL_CHANNEL = -3

        public const val DEFAULT_BUFFER_PROPERTY_NAME: String = "kotlinx.coroutines.channels.defaultBuffer"

        internal val CHANNEL_DEFAULT_CAPACITY = systemProp(DEFAULT_BUFFER_PROPERTY_NAME,
            64, 1, UNLIMITED - 1
        )
    }
}

public interface SendChannel<in E> {
    public suspend fun send(element: E)
}

public interface ReceiveChannel<out E> {
    public suspend fun receive(): E
}
```

채널의 생산자와 소비자는 다:다 관계이며 그 수에 제한이 없고, 채널은 FIFO 구조로 동작하기 때문에 소비자가 여럿이라도 같은 데이터를 중복해서 받을 수 없습니다. 

우리가 통신 개념에서 익히 알듯이 생산자와 소비자간에 데이터 처리 속도의 차이에 따라 문제가 발생할 수 있어, 채널에는 BUFFER 가 있고 버퍼 공간의 크기(CAPACITY)와 버퍼가 가득 찼을 때 데이터를 어떻게 처리할 것 인지의 방법에 따라 타입이 나뉩니다.

1. UNLIMITED: 채널의 버퍼의 크기가 무제한이어서 SendChannel#send 가 중단되지 않습니다.
2. RENDEZVOUS: 채널 버퍼의 크기가 0이고, 생산자와 소비자가 모두 데이터를 송신 및 수신하고 있을 때만 데이터를 교환할 수 있습니다.
3. CONFLATED: 채널의 버퍼의 크기가 1이고, 버퍼가 가득 찼을 때 가장 최신의 것을 유지합니다.
4. BUFFERED: 채널의 버퍼의 크기가 특정 수 만큼을 가집니다.

또 각 인터페이스의 메소드를 보면 해당 함수들이 suspend 인데, 데이터를 채널로 송신할 때 채널이 가득차 있거나, 데이터를 수신하려고 할 때 채널이 비어있을 때 중단됩니다. 

이렇듯 코루틴이 데이터를 송수신할 수 있는 채널에는 버퍼개념이 있고 버퍼의 오버플로우시 어떻게 수행할 것인가 에 대한 전략도 가지고 있습니다. 생산자는 소비자가 없어도 채널로 데이터를 보낼 수 있고, 채널은 버퍼공간에 쌓아뒀다가 소비자가 수신을 하려 할 때 버퍼에 쌓인 데이터를 전달합니다.

하지만, 이렇게 실시간으로 활성화 상태를 유지하는 채널은 그자체로 비용이 발생합니다. 또, 보통 네트워크 통신에서는 지속적으로 활성화 되지 않고 1회성으로 요청했을 때 응답받은 데이터를 처리합니다. 이런 특징을 Cold Stream 이라고 하며, 채널과 같이 실시간으로 활성화(Live)되어 있는 것을 Hot Stream 이라고 합니다. 채널은 기본적으로 Hot 하고, 네트워크 통신과 같이 데이터를 1회성으로 요청하는 Cold 를 지원하기 위해 Flow 가 제공되고 있습니다.

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

반면에, 안드로이드와 같은 클라이언트 환경에서는 UI 의 이벤트를 구독하다가 발생하면 바로 데이터를 변경하고, 변경된 데이터를 화면에 띄워주기 위한 흐름을 구현하는 것과 같은 반응형 프로그래밍 패러다임 적용을 필요로 합니다. 따라서 실시간으로 활성화 되어 있어야 하며, 옵저버패턴으로 일련의 동작들이 단계적으로 실행되어야 하는 Hot Flow 를 이용합니다.

Hot Flow 는 채널처럼 collect 와 같은 최종 연산이 없어도 활성화 되어 있습니다. 따라서, 언제든지 값이 방출(emit) 되면 replyCache 만큼 최신의 데이터를 가지고 있다가 구독자가 collect 시점에 데이터를 소비할 수 있습니다. 반면에, 채널과 달리 구독을 시작한 뒤로 준비하는 기간동안 받지 못한 데이터를 extraBufferCapacity 만큼 오버플로우 전략에 따라 관리하면서 들고 있을 수 있습니다. 또한, 채널의 데이터를 소비자가 FIFO 구조로 수신하는 것과 달리 모든 구독자들이 동시에 같은 데이터를 수신합니다.

Hot Flow에는 Shared Flow와 SharedFlow를 상속하는 State Flow 로 나뉘게 되며 조금의 다른 특징을 갖습니다.

# StateFlow vs SharedFlow
SharedFlow  를 생성하기 위해서 MutableSharedFlow() 팩토리함수를 이용합니다.

```kotlin
public fun <T> MutableSharedFlow(
    replay: Int = 0,
    extraBufferCapacity: Int = 0,
    onBufferOverflow: BufferOverflow = BufferOverflow.SUSPEND
): MutableSharedFlow<T> {
    require(replay >= 0) { "replay cannot be negative, but was $replay" }
    require(extraBufferCapacity >= 0) { "extraBufferCapacity cannot be negative, but was $extraBufferCapacity" }
    require(replay > 0 || extraBufferCapacity > 0 || onBufferOverflow == BufferOverflow.SUSPEND) {
        "replay or extraBufferCapacity must be positive with non-default onBufferOverflow strategy $onBufferOverflow"
    }
    val bufferCapacity0 = replay + extraBufferCapacity
    val bufferCapacity = if (bufferCapacity0 < 0) Int.MAX_VALUE else bufferCapacity0 // coerce to MAX_VALUE on overflow
    return SharedFlowImpl(replay, bufferCapacity, onBufferOverflow)
}
```

SharedFlow 를 만들기 위해 필요한 매개변수는 reply(구독 시점 이전 데이터를 몇개 받을 지), extraBufferCapacity(버퍼의 크기), onBufferOverFlow(오버플로우 전략) 입니다.  SharedFlow 는 현재값을 들고 있지 않기 때문에 구독자가 데이터를 소비하고 나면 소실되기 때문에 보통 이벤트를 처리하는 용도로 사용됩니다.

StateFlow 는 SharedFlow 를 상속받지만 replyCache가 1이고, extraBufferCapacity가 1이며, 버퍼가 가득찼을 때 가장 오래된 데이터를 제거하며, value 프로퍼티로 __현재 상태값__을 계속 들고 있습니다.

```kotlin
public fun <T> MutableStateFlow(value: T): MutableStateFlow<T> = StateFlowImpl(value ?: NULL)

private class StateFlowImpl<T>(
    initialState: Any // T | NULL
) : AbstractSharedFlow<StateFlowSlot>(), MutableStateFlow<T>, CancellableFlow<T>, FusibleFlow<T> {

    @Suppress("UNCHECKED_CAST")
    public override var value: T
        get() = NULL.unbox(_state.value)
        set(value) { updateState(null, value ?: NULL) }

    override fun compareAndSet(expect: T, update: T): Boolean =
        updateState(expect ?: NULL, update ?: NULL)

    override val replayCache: List<T>
        get() = listOf(value)

    override fun tryEmit(value: T): Boolean {
        this.value = value
        return true
    }

    override suspend fun emit(value: T) {
        this.value = value
    }

    override suspend fun collect(collector: FlowCollector<T>): Nothing {
        val slot = allocateSlot()
        try {
            if (collector is SubscribedFlowCollector) collector.onSubscription()
            val collectorJob = currentCoroutineContext()[Job]
            var oldState: Any? = null // previously emitted T!! | NULL (null -- nothing emitted yet)
            // The loop is arranged so that it starts delivering current value without waiting first
            while (true) {
                // Here the coroutine could have waited for a while to be dispatched,
                // so we use the most recent state here to ensure the best possible conflation of stale values
                val newState = _state.value
                // always check for cancellation
                collectorJob?.ensureActive()
                // Conflate value emissions using equality
                if (oldState == null || oldState != newState) {
                    collector.emit(NULL.unbox(newState))
                    oldState = newState
                }
                // Note: if awaitPending is cancelled, then it bails out of this loop and calls freeSlot
                if (!slot.takePending()) { // try fast-path without suspending first
                    slot.awaitPending() // only suspend for new values when needed
                }
            }
        } finally {
            freeSlot(slot)
        }
    }

    override fun fuse(context: CoroutineContext, capacity: Int, onBufferOverflow: BufferOverflow) =
        fuseStateFlow(context, capacity, onBufferOverflow)
}

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

StateFlow 의 가장 큰 차이점은 value 프로퍼티 입니다. 이름 그대로 현재 상태를 value 값을 통해 노출하며, replyCache 는 value값을 list에 담아 두고 있어 구독시점에 해당 현재 상태값을 바로 받아볼 수 있습니다. 또 현재 상태값은 비워 둘 수 없기 때문에 MutableStateFlow() 팩토리 함수로 초기값을 받아 value 로 할당합니다. 또 멀티스레드 환경 최적화를 위해 내부적으로 compareAndSet() 을 이용합니다.

따라서 UI 이벤트를 처리하는 것은 SharedFlow 로, UI 의 text와 같은 상태값을 노출하는 용도로는 StateFlow 를 이용하는 것이 좋습니다.