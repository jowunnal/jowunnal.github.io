---
title: "[Android] What is Job?"
categories:
- Coroutines
tags:
- Study
---

구글 개발자 Manuel Vivo는 Job에 대해서 이렇게 정의했다.

> A Job is a handle to a coroutine. For every coroutine that you create (by launch or async), it returns a Job instance that uniquely identifies the coroutine and manages its lifecycle. As we saw above, you can also pass a Job to a CoroutineScope to keep a handle on its lifecycle.

[출처 : Android Developer Coroutine:First things first](https://medium.com/androiddevelopers/coroutines-first-things-first-e6187bf3bb21 "Android Developer Coroutine:First things first")

즉, Job 은 Coroutine lifecycle을 제어해줄때 사용하는 객체이다. Job을 통해 본인이 만든 Coroutine의 생명주기를 cancel할것인지 join할것인지 등등을 처리할수 있다.

# Job's Lifecycle state
---
[![job lifecycle](/assets/job_lifecycle.png)](https://medium.com/androiddevelopers/coroutines-first-things-first-e6187bf3bb21 "Android Developer Coroutine:First things first")

1. New(all false) : Job이 생성된후 초기상태
2. Active(isActive=true) : Job이 생성후 사용하기에 준비된 상태. default로 Job은 생성된후 New->Active로 자동으로 상태가 변경된다.(자동변경 되지않으려면 CoroutineStart.Lazy로 실행)
3. Completing(isActive=true) : Job이 로직을 실행중인상태
4. Completed(isCompleted=true) : Job이 로직을 실행 완료한 상태
5. Cancelling(isCancelled=true) :  Job이 로직을 취소중인 상태
6. Cancelled(isCompleted,isCancelled=true) : Job이 로직의 취소가 완료된 상태

직접 lifecycle state에 접근은 불가능하며, 현재 lifecycle state가 어떠한지는 isActive(),isCompleted(),isCancelled() 를 통해 확인할수 있다.

# Control Job
---
개발자는 직접 상속된 코루틴의 생명주기를 관리하기위해 Job을 제어해야한다. 그렇다면 제어하기위해 사용할수있는 메소드는 뭐가있을까?

- start() : Job을 실행시키면서, Coroutine의 현재 동작상태를 확인한다. Completing이면 true를 리턴하고, Active이거나 Completed 이면 false를 리턴한다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch{
        delay(1000)
        println("Coroutine is started")
    }

    job.start()
}
```

메인쓰레드가 차단되는 runBlocking{ }블록의 새로운 코루틴내에서 위코드에서 job.start()를 통해 내부 코루틴의 "Coroutine is started" 문장이 출력될것이라 생각했다.

![job_start](/assets/job_start_1.PNG)

하지만, 동작결과 아무것도 출력되지 않은채로 종료됬다. 즉, A코루틴내의 B코루틴은 job.start()에 의해 수행이 시작되지만 A코루틴이 종료되면서 내부코루틴인 B도함께 종료되어 delay에 의해 출력되지 않은것이다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch{
        delay(1000)
        println("Coroutine is started")
    }
		
		delay(2000)
    job.start()
}
```

![job_start_2](/assets/job_start_2.PNG)

따라서 main문의 코루틴이 종료되지 않게끔, delay를 주었다. 그런데, 조금이상하다? job.start() 이전에 delay를 주엇는데 왜 job이 실행되고 있지?

Job은 생성과 동시에 default적으로 New->Active로 lifecycle이 변경되어 수행된다. 따라서 job.start()가 수행되기 전에 job을 실행시키지 않기 위해서는 CoroutineStart.Lazy로 선언해야한다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        delay(1000)
        println("Coroutine is started")
    }

    delay(2000)
    job.start()
}
```

위와같이 변경하면, 아무것도 출력되지 않는다.

![job_start](/assets/job_start_1.PNG)

이번에는 job.start() 이 수행되었을때 job이 completing 상태이면 true, active 이거나 complted 이면 false를 리턴하는 job의 상태값을 확인해 보자

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        for(i in 1..5){
            println("Coroutine is completing : $i")
            delay(500)
        }
        println("Coroutine is started")
    }

    if(job.start()){
        println("Job is Completing!!")
    }else{
        println("Job is Active or Completed!!")
    }
    delay(2000)
}
```

if문 내부의 조건을 체크함과 동시에 job.start에 의해 job이 completing이 된다. 따라서 true가 반환되기 때문에 "Job is Completing!!"문장이 출력되고, 그이후 코루틴 내부 for문에 이 수행됨을 알수있다.

![job_start](/assets/job_start_3.PNG)


-  join() : 현재수행중인 Coroutine 이 완료될때까지 대기한다. launch{ }블록에서 사용시 async의 await()처럼 사용할수 있다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        println("Coroutine has started")
        for(i in 1..5){
            println("Coroutine is completing : $i")
            delay(500)
        }
    }

    job.join()
}
```

앞의 job.start()와 달리 job.join()은 코루틴이 완료될때까지 대기하기 때문에 따로 delay를 걸지않아도 내부코루틴을 모두 수행함을 볼수있다. ( 코루틴을 start 하고 완료상태까지 대기함)

![job_start](/assets/job_join_1.PNG)


-  cancel() : 현재 수행중인 Coroutine을 취소한다. 단, cpu-comsuming code 인경우(반복문) 로직이 완료된후 블럭에서 빠져나오면 cancel한다. 또한, cancel 될경우 반드시 CancellationException이 발생한다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        println("Coroutine has started")
        for(i in 1..5){
            println("Coroutine is completing : $i")
            delay(500)
        }
    }

    job.start()
    delay(1000)
    job.cancel()
		delay(2000) // 부모코루틴이 종료되면서 내부코루틴이 종료된건지 cancel에의해 종료된건지 확인하기위한 delay
}
```

![job_start](/assets/job_cancel_1.PNG)

job이 start되고나서 1초잇다가 cancel()을 수행시켯더니 1~2 만큼만 출력되고 취소됨을 볼수있다. Coroutine은 cancel됫을때 항상 CancellationException이 발생하는데 이를통해 코루틴의 Exception Handling을 해주어야 한다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        println("Coroutine has started")
        for(i in 1..5){
            println("Coroutine is completing : $i")
            delay(500)
        }
    }

    job.start()
    delay(1000)
    job.cancel("Job is cancelled")
    println(job.getCancellationException())
    delay(2000)
}
```

![job_start](/assets/job_cancel_2.PNG)

job.cancel()의 파라미터에 message인자를 삽입하여 취소됬을때 출력메세지를 만들수있고, job.getCancellationException()을 통해 발생되는 CancellationException을 throw 처리할수있다.

더 자세한 예외처리는 따로 작성하겠다.

###### cpu-consuming 작업을 수행중일때 cancel()을 수행해도 재대로 동작하지 않는 문제점이 있다.
```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        println("Coroutine has started")
        for(i in 1..10){
            println("Coroutine is completing : $i")
        }
    }

    job.start()
    delay(1000)
    job.cancel("Job is cancelled")
    println(job.getCancellationException())
    delay(2000)
}
```

![job_start](/assets/job_cancel_3.PNG)

반복문과 같은 cpu-consuming 작업을 수행중일때는 cancel()을하여도 1~10까지 모두 출력됨을 볼수있다. 이를해결하려면 어떡해야 할까?

- 방법1. suspend를 걸어준다.

앞의 예시처럼 반복문내부에 delay를 걸어줌으로써 suspend에 의해 현재 Coroutine의 cancellation을 확인하고 중지할수있다.

- 방법2. 명시적으로 isActive()를 통해 상태를 체크한다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        println("Coroutine has started")
        for(i in 1..3000){
            if(isActive){
                println("Coroutine is completing : $i")
            } else{
                println("Coroutine is Cancelled")
                return@launch
            }
        }
    }

    job.start()
    job.cancel()
    println(job.getCancellationException())
    delay(2000)
}
```

![job_start](/assets/job_cancel_4.PNG)

명시적으로 isActive를통해 job의 상태를 체크하고 active가 아니면 (종료되었으면) return@launch를통해 코루틴을 중지시키는 방법을 사용할수도 있다.

- 방법3. timeout을 사용한다.

timeout 방법의경우 정해진시간보다 오래걸리는 경우에 종료시키는 방법이다.

```kotlin
fun main(): Unit = runBlocking{
    withTimeout(1000){
        for(i in 1..10){
            println("Coroutine is completing : $i")
            delay(300)
        }
    }
}
```

![job_start](/assets/job_cancel_5.PNG)

withTimeout 블록은 코루틴스쿠프를 생성하고 invoke안의 파라미터상에 들어온 시간보다 오래걸리면 TimeoutCancellationException 을 발생시키고 종료된다.

또는 withTimeoutOrNull 도 사용할수있다.

```kotlin
fun main(): Unit = runBlocking{
    val coroutine = withTimeoutOrNull(1000){
        for(i in 1..10){
            println("Coroutine is completing : $i")
            delay(300)
        }
    }
    println("Coroutine is $coroutine")
}
```

![job_start](/assets/job_cancel_6.PNG)

withTimeoutOrNull은 Timeout이 발생하면 null을 리턴하고 종료된다.


-  cancelAndJoin() : 현재 수행중인 Coroutine을 취소시키고 , 정상종료 까지 대기한다.

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch(start=CoroutineStart.LAZY){
        println("Coroutine has started")
        for(i in 1..10){
            println("Coroutine is completing : $i")
            delay(200)
        }

    }
    job.start()
    job.cancelAndJoin()
    delay(2000)
}
```

![job_start](/assets/job_cancelAndJoin.PNG)

cancel() 후 join()을 하나, cancelAndJoin()을 하나 똑같이 수행된다. 수행중인 Coroutine을 취소시키고 정상종료까지 대기한다.


-   cancelChildren() : 현재 수행중인 Coroutine Scope내의 자식Coroutine 만을 모두 취소한다. (현재수행중인 Coroutine은 취소하지 않음)

```kotlin
fun main(): Unit = runBlocking{
    val job= CoroutineScope(Dispatchers.Default).launch{
        println("Coroutine has started")
        for(i in 1..10){
            println("Parent Coroutine is completing : $i")
            delay(200)
        }
        launch {
            for(i in 1..10){
                println("Child Coroutine is completing : $i")
                delay(300)
            }
        }

    }
    job.cancelChildren()
    delay(2000)
}
```

![job_start](/assets/job_cancelChildren.PNG)

job코루틴 내부의 자식코루틴은 수행되지 않음을 볼수있다.
