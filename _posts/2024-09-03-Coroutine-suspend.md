---
title: "[Kotlin] Coroutine : Suspend 살펴보기 "
categories:
- Coroutines
tags:
- Study

toc: true
toc_sticky: true
toc_label: 목차
---

Jetsbrains 의 Kotlin 은 비동기 작업을 쉽게 동기로 작성하고 실행할 수 있는 기능을 제공하는 라이브러리 입니다. Coroutine 의 핵심인 Suspend 키워드는 Kotlin Compiler 가 compile time 에 특정 코드를 생성 및 변환하여 스레드를 블로킹 하지 않고 __중단__시킴으로써 더 효율적으로 동작합니다.

오늘 살펴볼 내용은 Coroutine 의 suspend 가 어떤 코드들을 생성하고, 나아가서 어떤 원리로 동작 하는지를 살펴보는 것 입니다.

# Why Coroutine?

I/O 작업과 같은 비동기 작업을 수행시키기 위해서 우리는 Thread 를 이용합니다. Java의 Thread 인스턴스는 생성과 관리에 대한 비용이 굉장히 큽니다. 그래서 보통 ThreadPool 공간에 인스턴스를 생성해두고 재사용 하는 방법을 채택하고 있습니다만 관리의 입장에서 예외가 발생했거나 특정 상황에서 스레드를 종료시키고 싶거나 스레드들을 전환할 때 굉장히 어렵습니다. 또한 스레드를 생성하고 I/O 작업을 실행하면 완료될 때 까지 현재 스레드가 __Blocking__ 되어 자칫 I/O 작업에서 문제가 생기거나 오래 걸리게 되는 경우 다른 작업을 하지 못해 안좋은 UX 를 제공할 수 있습니다.

특히, 안드로이드에서는 UI 그리기를 담당하는 Main Thread 가 존재하고 이 스레드를 블로킹하면 ANR 이 발생하여 앱 프로세스가 종료될 수 있기 때문에 보통 Thread 인스턴스를 생성하여 별도 작업을 실행하고 그 결과를 화면에 노출하기 위해 runOnUiThread 람다에서 실행하곤 합니다.

```kotlin

override fun onCreate(bundle: Bundle) {
    thread {
        val apiResults = getResultsFromApi()
        runOnUiThread {
            text.setText(apiResults)
        }
    }
}

```

하지만 위 코드는 그렇지 않을 수도 있지만 몇개의 스레드를 더 이용하거나 전환한다면 코드의 복잡도가 매우 커지고 관리에서도 굉장히 어려워짐을 볼 수 있습니다. 이 때 우리는 Coroutine 을 이용하여 Jetbrains 에서 말하는 Dream code 를 작성할 수 있습니다.

```kotlin

override fun onCreate(bundle: Bundle) {
    lifecycleScope.launch {
        val apiResults = getResultsFromApi()
        text.setText(apiResults)
    }
}

suspend fun getResultsFromApi(): String {
    val data = getResultsFromRepo()
    return data
}

```

한눈에 보기에도 굉장히 코드가 단순해 졌습니다. 어떻게 이런 코드를 작성할 수 있을까요? 정답은 Coroutine 의 Suspend 에 있습니다.

# Suspend

suspend 키워드로 작성된 메소드는 호출지점에서 __중단__ 된 후 해당 메소드의 결과값을 반환하면서 원래의 실행 흐름에서 __재개__ 됩니다. 이러한 실행흐름은 현재 스레드를 블로킹하지 않고, 코루틴이 중단되었을 때 다른 코루틴의 작업이 스레드에 할당됨으로써 더 효율적으로 동작할 수 있게 됩니다.

또한, 원래의 실행흐름을 보장하기 위해서 Suspend 로 작성된 함수는 Compile time 에 원래의 실행 흐름에 대한 정보를 저장하는 Continuation 이라는 인스턴스를 생성하고 중단함수의 매개변수로 삽입하게 됩니다. 이 Continuation 을 다른 말로 __상태 머신__ 이라고도 부릅니다.

``` kotlin

override fun onCreate(bundle: Bundle) {
    lifecycleScope.launch {
        val apiResults = getResultsFromApi()
        text.setText(apiResults)
    }
}

suspend fun getResultsFromApi(cont: Continuation<String>): Any {
    val continuation = object : ContinuationImpl(cont) {
        override val context: CoroutineContext get() = cont.context
        var result: String? = null
        var label = 0
        var data = ""

        override fun resumeWith(result: Result<String>) {
            val res = try {
                val r = getResultsFromApi(this)
                if (r == COROUTINE_SUSPEND)
                    return

                Result.success(r as String)
            } catch (e: Throwable) {
                Result.failure(e)
            }
            cont.resumeWith(res)
        }
    }

    var data = ""

    if (continuation.label == 0) {
        data = ""
        continuation.data = data
        continuation.label = 1
        if (getResultsFromApi(cont) == COROUTINE_SUSPEND)
            return COROUTINE_SUSPEND 
    }

    else if (continuation.label == 1) {
        data = continuation.data as String
        return data
    }

    throw IllegalStateException("error")
}

```

생성된 Continuation 인스턴스는 getResultsFromApi() 함수만의 새로운 Continuation 클래스로 decorate 되고, 함수의 지역변수들과 실행 흐름을 저장하기 위한 label 을 가지면서 콜스택을 유지할 수 있습니다. 

## Call Stack

프로그래밍에서 함수는 호출 후 실행된 후 결과를 리턴하고 그 흐름을 순차적으로 이어서 수행하게 됩니다. 그러기 위해서 Stack 공간에 해당 함수의 지역변수와 같은 상태들을 저장합니다. 하지만 코루틴이 중단될 경우 스레드를 내 놓게 되고, 스레드에 있는 스택 공간의 상태 정보들을 잃기 때문에 Continuation 을 콜 스택으로 이용하게 됩니다.

중요한 점은 중단함수 내에는 또다른 중단함수가 호출될 수 있기 때문에 코루틴의 structured concurrency 를 보장하기 위해 상위 Continuation의 CoroutineContext 를 하위로 끝까지 전파합니다.

## Structured Concurrency

구조화된 동시성은 코루틴 빌더로 생성된 코루틴들은 CoroutineContext 를 상속하여 부모-자식 관계를 가지면서, 4가지의 특성을 보이는 것을 의미합니다.

1. 자식 코루틴은 부모 코루틴으로 부터 CoroutineContext 를 상속받습니다. (단, Job 은 상속되지 않으며, 자식 코루틴의 Job 에 대한 부모(parentContext)로 할당됩니다.)
2. 부모 코루틴은 자식 코루틴들이 모두 완료(Completed)될 때 까지 중단됩니다.
3. 부모 코루틴이 취소되면, 자식 코루틴들도 모두 취소됩니다.
4. 자식 코루틴에서 발생한 예외는 부모 코루틴으로 전파되며, 모두 완료됩니다. 단, CancellationException(취소로 인한 예외) 은 전파되지 않습니다.

kotlin compiler 는 suspend 함수 호출을 기준으로 switch-case 문으로 labeling 하게 됩니다. label 정보는 현재의 실행 흐름을 판단하는 기준이 되며 Continuation 내에 저장됩니다. 또, suspend 함수의 반환 타입이 Any 인 이유는 중단함수는 COROUTINE_SUSPEND 라는 상수를 리턴하기 때문입니다.

## COROUTINE_SUSPEND

앞서 보았듯이 중단함수가 호출되면, 해당 지점에서 코루틴은 __중단__ 되어 현재의 코루틴이 스레드를 내놓고 다른 코루틴이 스레드를 점유하게 됩니다. 이를 통해 스레드를 블로킹하지 않아 더 나은 성능을 보장할 수 있습니다. 이러한 동작이 수행되는 이유는 중단함수가 COROUTINE_SUSPEND 를 반환하기 때문입니다.

COROUTINE_SUSPEND 는 단순히 상수이며, 이 값이 리턴되면 콜스택의 끝까지 해당 상수를 리턴합니다. 결론적으로 해당 콜스택을 벗어나게 되고, 다른 코루틴이 스레드를 점유할 수 있게 되는 것 입니다.

![suspend_coroutine](/assets/coroutine_suspendCoroutine.PNG)

위 사진에서 코루틴스쿠프가 실행되면 코루틴 A 가 스레드를 점유합니다.(여기서는 설명을 위해 단일스레드라고 생각하겠습니다. 실제로는 디스패쳐가 가지고 있는 스레드풀의 워커스레드들이 FIFO 구조로 각 작업을 실행하게 됩니다.) 이후 suspend function 1 을 실행하면서 결과적으로 suspend function 3까지 실행된 후 COROUTINE_SUSPEND 를 콜스택 전체에서 반환하면서 벗어나면서 코루틴 B가 스레드를 점유합니다. 다시, 코루틴 B의 suspend function 4 를 호출하면 결과적으로 suspend function 6 까지 실행된 후 COROUTINE_SUSPEND 를 반환하면서 콜스택에서 벗어나고 코루틴 A가 스레드를 점유합니다. 위의 실행 흐름으로 코루틴들의 코드들이 모두 실행됩니다.

그렇다면 콜스택에서 벗어난 뒤, 다시 원래의 실행흐름으로 어떻게 돌아올까요?

## ResumeWith()

결론적으로 중단된 코루틴을 재개하기 위해서는 Continuation 인터페이스의 resumeWith() 를 호출해야 합니다. 함수의 실행이 끝나면 외부에서 resumeWith() 를 호출하면서 중단 지점부터 재개하게 되며, 최초 호출 함수까지 중단함수를 재개하면서 코루틴이 완료(Completed)됩니다.

