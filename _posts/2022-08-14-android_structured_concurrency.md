---
title: "[Android] Structured Concurrency"
categories:
- Coroutines
tags:
- Study
---

[세체한님의 유튜브](https://www.youtube.com/channel/UCJeARDV434voq3IxRTBfzLw "link")영상중 Coroutine의 강의영상을 보고 [What is Job?](https://jowunnal.github.io/coroutines/coroutine_job/ "what is job")이후 연계되는 코루틴의 학습코멘트를 남겨보고자 한다.

# Structured Concurrency
---
[코틀린공식 가이드](https://kotlinlang.org/docs/coroutines-basics.html#structured-concurrency "kotlin Guild")에서 structured concurrency에 대해서 이렇게 설명한다.

>  Structured concurrency ensures that they are not lost and do not leak. An outer scope cannot complete until all its children coroutines complete. Structured concurrency also ensures that any errors in the code are properly reported and are never lost.

해석하자면, 부모코루틴의 동일스쿠프상의 자식코루틴들이 모두수행될때까지 종료되지 않고 에러가  report되며 누락되지 않는다.

[what is job?](https://jowunnal.github.io/coroutines/coroutine_job/ "link")에서 설명햇듯이 새로운 CoroutineScope 에서 선언된 코루틴들은 job.join() 혹은 .await()을통해 완료됨을 보장해주지 않으면 부모코루틴이 종료되면서 자식들도 함께 종료됬었다. 하지만 같은 스쿠프상의 자식코루틴들은 완전히 종료됨을 보장한다.

 직접 코드를통해 확인해보자.
 
 ```kotlin
fun main(): Unit = runBlocking {
    launch {
        println("Coroutine A has started")
        delay(1000)
    }
    launch {
        println("Coroutine B has started")
        delay(1000)
    }
}
```

![structuredConcurrency](/assets/structuredConcurrency_1.PNG)

위와같이 자식launch{ }블록들이 모두 수행될때까지 프로그램이 종료되지 않았다.

main문은 UI스레드를 차단하는 runBlocking{ } 코루틴블럭의 로직을 수행하고, 내부에 수행되는 launch{}블록들은  부모코루틴의 스쿠프를 그대로 inherit 받기 때문에 자식launch{ }블록들이 모두 수행될때까지 runBlocking{ }은 종료되지 않는 모습을 보여준다.

또한, 이는 Cancellation 에서도 동일하게 수행된다. 부모코루틴이 cancel()되거나 예외가 발생하면, 자식코루틴들도 모두 cancel() 과 예외 발생의 영향을 받는다.

```kotlin
fun main() {
    val job = CoroutineScope(Dispatchers.Default).launch {
        launch(Dispatchers.IO) {
            println("Coroutine A has started")
            delay(1000)
        }
        launch{
            println("Coroutine B has started")
            delay(1000)
        }
    }

    job.cancel()
    Thread.sleep(2000)
}
```

![structuredConcurrency](/assets/structuredConcurrency_2.PNG)

이렇게 선언된 코루틴스쿠프는 하나의 job객체를 통해서 자식코루틴들 까지 모두 cancel() 할수있기때문에 View가 종료될때(activity or fragment) 부모코루틴 하나의 생명주기만 처리해주면 따로 더 추가적인 cancel() 작업이 필요없게 된다. 만약, 서로다른 생명주기상의 컨트롤이 필요하다면 새로운 코루틴스쿠프를 생성해서 동작시켜야함을 유의하자.

# Suspend Function
---
[2019 Google I/O](https://www.youtube.com/watch?v=BOHK_w09pVA "youtube")에서 네트워크통신과 UI작업을 하나의 function에서 작성이 suspend를 통해 가능하다고 말한다. 이를 Dream Code라고 설명하는데, 다음과같다.

```kotlin
suspend fun DreamCode(){
	val user = api.fetch()
	show(user)
}
```

 [코틀린공식 가이드](https://kotlinlang.org/docs/coroutines-basics.html#structured-concurrency "kotlin Guild")에서 설명하듯이,

> A coroutine is an instance of suspendable computation.

코루틴은 suspendable computation 의 instance이다. (정지가능한 computation의 객체라는 말이다.) 또한,

> However, a coroutine is not bound to any particular thread. It may suspend its execution in one thread and resume in another one.

특정쓰레드에 bound 되는것이 아닌 한스레드에서 suspend 하고 다른스레드에서 resume 할수있는것 이라고 설명한다.

즉,  하나의 routine 에서 라인단위로 suspend 를통해 중지 하고 resume(재개) 하는 작업의 반복을 통해 우리는 코드상에서 네트워크통신과 UI작업을 같이 작성할수 있는것이다.

이는 코루틴의 내부구조를 들여다보면 더 자세히 알수 있다.

[2017 KotlinConf](https://www.youtube.com/watch?v=_hfBv0a09Jc "youtube") 를 참고바란다.

요약하자면, 코루틴을 switch-case문으로 바꾸고 CPS(Continuation Passing Style)객체를 매개변수로 받아 suspend function의 상태를 저장한다. 이를 callback parameter로 사용하여 각 case문이 동작하고나서 다음case문을 수행(resume)하도록 하는것이다.[세차원님의 유튜브](https://www.youtube.com/watch?v=DOXyH1RtMC0&list=PLbJr8hAHHCP5N6Lsot8SAnC28SoxwAU5A&index=5 "link")

따라서 suspend-resume 구조를 바탕으로 Dream code를 작성할수 있다고 말한다.

## Sequential by default
suspend Function들은 sequential 하게 수행된다. 그이유는 위와같이 suspend-resume의 구조이기 때문. 코드를 보면서 살펴보자

```kotlin
fun main() = runBlocking {
    doSomething1()
    doSomething2()
    println("$this is end")
}

suspend fun doSomething1(){
    delay(1000)
    println("done 1!!")
}

suspend fun doSomething2(){
    delay(1000)
    println("done 2!!")
}
```

![structuredConcurrency](/assets/structuredConcurrency_3.PNG)

dosomething1()이 수행되고나서, dosomething2()가 수행되고 print문이 찍혔다. 즉, 위의 설명과같이 첫번째 dosomething1()이 switch의 case1:이되고, dosomething2()는 case2: , 마지막println()은 case3: 이되어 차례대로 수행되고 종료되는 모습이다.

## Async-Style Function
먼저 코드를 보자면,
```kotlin
fun main(){
    try {
        doGlobalSomething1()
        doGlobalSomething2()
        throw Exception("Exception")
    }catch (e:Exception){
        println("$e is happened!!")
    }
    Thread.sleep(3000)
}

fun doGlobalSomething1() = GlobalScope.async {
    doSomething1()
}
fun doGlobalSomething2() = GlobalScope.async {
    doSomething2()
}

suspend fun doSomething1(){
    delay(1000)
    println("done 1!!")
}
suspend fun doSomething2(){
    delay(1000)
    println("done 2!!")
}

```

![structuredConcurrency](/assets/structuredConcurrency_4.PNG)

위코드는 코루틴스쿠프 자체를 function으로 사용하는 코드이다. 

Jetbrains에서는 위와 같은 style로 코드를 작성하지 말라고 권고하고있다.  GlobalScope의 경우 [Coroutine](https://jowunnal.github.io/coroutines/coroutines/ "link")에서 간략하게 설명햇듯이 application의 lifecycle을 따르기때문에 예외나 취소가 발생했을경우의 처리를 따로 해줘야한다. 그렇지않으면 백그라운드상에서 예외나 취소가 발생했음에도 동작이 계속된다.

그러면 GlobalScope가 아닌 CoroutineScope로 하면 예외가 발생했을때 코루틴이 중지될까? 이것도 당연히 아니다.

맨처음에서 말했듯이, 부모코루틴의 취소나 예외가 발생했을때 자식코루틴이 영향을 받는것은 Structured Concurrency 를 적용한 코루틴에서만 가능하다.

즉, 이들에대한 예외 handling을 따로하던지 아니면 같은 Scope상에서 동작하게 할것인지를 결정해야 한다는 것이다.

어쨋든 위와같은 style(코루틴스쿠프 자체를 method로 사용하는 방식)로 코드를 작성하게되면 excetion handling에서 문제가 발생할 여지가 있으니, jetbrains에서는 다시 Structured Concurrency 방식으로 코드를 작성할것을 권고한다.

### Structured Concurrency Async

```kotlin
fun main()= runBlocking {
    try {
        doGlobalSomethings()
    } catch (e: Exception) {
        println("$e is happened!!")
    }
    Thread.sleep(3000)
}

suspend fun doGlobalSomethings() = coroutineScope{
    val one=async{
        doSomething1()
        throw Exception("Exception")}
    val two=async{doSomething2()}
    one.await()
    two.await()
}

suspend fun doSomething1(){
    delay(1000)
    println("done 1!!")
}
suspend fun doSomething2(){
    delay(1000)
    println("done 2!!")
}
```

![structuredConcurrency](/assets/structuredConcurrency_5.PNG)

위와같이 각 모듈의 suspend function을 하나의 코루틴스쿠프내에서 동작하는 suspend function을 만들어서 수행시키게 되면  예외발생시 예외에의해 수행되지않고 종료된다.

물론, 코루틴스쿠프를 다르게하여 각 method마다 동작하는 lifecycle이 달라야한다면 이들에대한 exception handling도 달라질것이고 그에맞게 job lifecycle 자체를 따로 handling하면 될것이라 생각한다.

어디까지나 관련성있는 모듈끼리의 연산 또는 그러한 로직수행인 경우에 동일한 스쿠프상에 존재해야만 lifecycle을 handling하고 exception 을 handling하기가 편하다는 소리인것같다.

# 끝으로
kotlin의 coroutine에 한발짝더 가까이간것같다. 추가적으로 exception handling에 대한부분들의 공부가 필요하다.
# References
---
https://www.youtube.com/watch?v=hfBv0a09Jc

https://kotlinlang.org/docs/composing-suspending-functions.html#structured-concurrency-with-async

https://www.youtube.com/watch?v=Vs34wiuJMYk&list=PLbJr8hAHHCP5N6Lsot8SAnC28SoxwAU5A&index=1
