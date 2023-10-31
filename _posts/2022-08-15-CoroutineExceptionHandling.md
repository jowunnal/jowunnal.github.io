---
title: "[Coroutine] Exception Handling"
categories:
- Coroutines
tags:
- Study

toc: true
toc_sticky: true
toc_label: "목차"
---

[Strucutred Concurrency](https://jowunnal.github.io/coroutines/android_structured_concurrency/ "link") 에 이어서 Exception Handling에 대해서 알아보자.

# Exception Propagation
---
Exception은 기본적으로 같은Scope상에 존재한다면(=부모와 자식간의 코루틴이라면) 예외를 propagtion(전파)하는 특징을 갖는다. 

코드를 보면서 살펴보자.

```kotlin
fun main(): Unit = runBlocking {
    launch {
        throw ArithmeticException("Exception")
    }.join()
    println("I'm running")
}
```

![Coroutine_Exception_Handling_1](/assets/Coroutine_ExceptionHandling_1.PNG)

runBlocking{ }에있는 I'm running이 출력되지않은채 종료된 모습이다. 만약 다른 scope로 존재하는 코루틴에서 예외가 발생하면 어떻게 될까?

같은 로직에서 내부의 launch{ }블록을 새로운 코루틴스쿠프에서 동작해도록 해보자.

```kotlin
fun main(): Unit = runBlocking {
    CoroutineScope(Dispatchers.Default).launch {
        throw ArithmeticException("Exception")
    }.join()
    println("I'm running")
}
```

![Coroutine_Exception_Handling_2](/assets/Coroutine_ExceptionHandling_2.PNG)

I'm running이 출력되는 모습을 볼수있다. 

# Exception And Cancel
---
코루틴이 cancel()될 경우 CancellationException이 발생한다는것은 [이전글](https://jowunnal.github.io/coroutines/coroutine_job/ "link")을 통해 배운 사실이다. 

그런데 같은scope상에 존재하는 child 에서 cancel()로 인해 발생되는 CancellationException은 부모로 전파되지 않는다.

```kotlin
fun main(): Unit = runBlocking {
    val job = launch {
        println("Coroutine A is completed")
    }
    job.cancel()
    delay(1000)
    println("I'm running")
}
```

![Coroutine_Exception_Handling_3](/assets/Coroutine_ExceptionHandling_3.PNG)

cancel로 발생하는 CancellationException과 이외의 다른 Exception들은 다르게 처리된다는 부분을 인지해야 한다.

그렇다면, 코루틴스쿠푸 A내부의 코루틴스쿠프B에서 취소가됫을때는 어떻게될까?

답은 당연히 B만취소가되고 A는 그대로 출력된다. 그렇다면 그 반대의 상황은 어떻게 될까?

답은 당연히 A가취소되면 B의코루틴도 취소된다. 

마찬가지로, [Structured Concurrency](https://jowunnal.github.io/coroutines/android_structured_concurrency/ "link") 에서봣듯이 동일scope 상의 부모 코루틴의 cancel()이 발생하면 자식들도 모두 cancel()된다.

# Exception Handling
---
보통 우리는 코드상에서 예외처리를 한다고하면 try-catch 문을 사용한다. 이를 한번 적용해보겠다.

```kotlin
fun main():Unit = runBlocking {
    launch {
        try{
            println("Coroutine A has error")
            throw ArithmeticException()
        }
        catch (e:ArithmeticException){
            println("$e is happened")
        }
    }
}
```

![Coroutine_Exception_Handling_4](/assets/Coroutine_ExceptionHandling_4.PNG)

Structured Concurrency의 자식코루틴에서 try-catch문을 사용하여 예외를 검출해보았다. 보통 try-catch문은 이러한패턴으로 코루틴내부의 로직에서 예외를 검출하고 처리하는데 사용된다.

그와달리 코루틴자체를 try-catch문으로 예외를 검출하면 어떻게될까?

```kotlin
fun main():Unit = runBlocking {
    try {
        launch {
            println("Coroutine A has error")
            throw ArithmeticException()
        }
    }catch (e:ArithmeticException){
        println("$e is happened")
    }
    delay(1000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_5](/assets/Coroutine_ExceptionHandling_5.PNG)

catch에서 예외를 검출하지 못하고 마지막println 문장을 출력하지못한채 강제종료됬다. 

처음 설명햇듯이 동일scope상의 코루틴은 예외를 propagation한다고 했다.  그렇다면 다른내부의 Scope상에서 발생한 예외는 try-catch문으로 처리가 될까?

```kotlin
fun main():Unit = runBlocking {
    try {
        CoroutineScope(Dispatchers.Default).launch {
            println("Coroutine A has error")
            throw Exception()
        }
    }catch (e:Exception){
        println("$e is happened")
    }
    delay(2000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_6](/assets/Coroutine_ExceptionHandling_6.PNG)

강제종료되지는 않고 마지막 println 문을 수행하기는 하지만 catch한 예외를 출력해주지를 않는다. 즉, try-catch문을 사용하는 예외처리는 coroutineScope내부의 로직에 대한 예외를 처리할때만 사용하고 Coroutine자체에 대한 예외처리는 try-catch로 하면 안된다.

코루틴의 예외처리 방법은 크게 2가지이다.

- CoroutineExceptionHandler 를 할당한다.

[Coroutine](https://jowunnal.github.io/coroutines/coroutines/ "link")에서 CoroutineContext의 4가지 구성요소에 대해서 설명한대로, CoroutineExceptionHandler를 선언한뒤 CoroutineContext에 할당하면된다.

```kotlin
val handler = CoroutineExceptionHandler { coroutineContext, throwable ->
    println("$throwable is happened")
}
fun main():Unit = runBlocking {

    CoroutineScope(Dispatchers.Default+handler).launch {
        println("Coroutine A has error")
        throw Exception()
				println("Coroutine A is completed")
    }
    
    delay(2000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_7](/assets/Coroutine_ExceptionHandling_7.PNG)

CoroutineContext의 경우 '+' 연산자를 통해 4가지구성요소 들을 CoroutineContext로 할당할수있다.(연산자중복으로 보인다)

위의 결과물에서 볼수있는것은 runBlocking 과 CoroutineScope는 서로다른 scope 이기때문에 예외가 발생했어도 취소되지 않고 마지막println()문장은 수행되었다는점 과 handler에 선언된 대로 예외가 처리되었다는점 그리고 예외가발생한 직후 Coroutine이 cancel()되었음  을 알수있다.

또한,  동일한 스쿠프상의 child에서 예외가 발생해도 예외는 전파되는 성질이 있기때문에 부모에 handler를 할당하면 부모에서 예외를 처리한다.

```kotlin
val handler = CoroutineExceptionHandler { coroutineContext, throwable ->
    println("$throwable is happened")
}
fun main() {
    CoroutineScope(Dispatchers.Default + handler).launch {
        launch {
            println("Coroutine A has error")
            throw Exception()
        }.join()
        println("root Coroutine is completed")
    }
    Thread.sleep(2000)
}
```

![Coroutine_Exception_Handling_8](/assets/Coroutine_ExceptionHandling_8.PNG)

부모코루틴내의 child코루틴이 여러개일 경우에도 하나의child 에서 예외가 발생했을때 부모로전파되고, 부모에서 예외를 잡기때문에 자식들도 모두 취소된다.

취소의 경우는 어떠할까? 위에서 보앗듯이 CancellationException은 전파되지 않는 특징을 보였다.

```kotlin
val handler = CoroutineExceptionHandler { coroutineContext, throwable ->
    println("$throwable is happened")
}
fun main():Unit = runBlocking {

    CoroutineScope(Dispatchers.Default+handler).launch {
        println("Coroutine A is completed")
    }.cancel()

    delay(2000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_8](/assets/Coroutine_ExceptionHandling_9.PNG)

애초에 예외자체로 처리되지 않는다. 즉, CoroutineExceptionHandler는 cancel()을 예외로 처리하지 않는 모습이다.

두번째 방법
- superVisorScope 또는  SuperVisorJob 을 이용한다.

SuperVisor의 경우 예외를 자식으로만 전파하는 특징을 갖는다. 먼저 superVisorScope는 coroutineBuilder이며 살펴보자면,

```kotlin
fun main():Unit = runBlocking {

    supervisorScope {
        println("Coroutine A is started")
        launch {
            throw Exception()
						launch {
                println("Coroutine Child B is started")
            }
            println("Coroutine Child A is started")
        }.join()
        println("Coroutine A is completed")
    }

    delay(2000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_10](/assets/Coroutine_ExceptionHandling_10.PNG)

superVisorScope 빌더내의 자식 launch{}에서 예외가 발생하였음에도 Coroutine A is Completed가 출력되었음을 볼수있다. 예외가 발생했어도 자식에서만 전파되기때문에 내부의 Coroutine A 와 B는 모두 출력되지않는다.

SuperVisorJob의 경우 Job객체이기 때문에 CoroutineContext 4가지구성요소중 하나인 Job객체로서 할당하면 된다. 자식코루틴빌더에 SuperVisorJob()객체를 CoroutineContext로 할당하면 자식으로만 예외를 전파하게 된다.

```kotlin
val handler = CoroutineExceptionHandler { coroutineContext, throwable ->
    println("$throwable is happened")
}
fun main():Unit = runBlocking {
    CoroutineScope(handler).launch {
        println("Coroutine A is started")
        launch(SupervisorJob()) {
            throw Exception()
            val job = launch {
                println("Coroutine Child B is started")
            }
            println("Coroutine Child A is started")
        }.join()
        println("Coroutine A is completed")
    }

    delay(2000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_11](/assets/Coroutine_ExceptionHandling_11.PNG)

결과물을 통해 확인이 가능하다.

# Async CoroutineException
---
async의 경우 .await()이 호출되기 전까지는 예외를 인식하지 못한다.

```kotlin
fun main():Unit = runBlocking {
    val job = CoroutineScope.async {
        println("Coroutine A is started")
        launch {
            throw Exception()
            println("Coroutine Child A is started")
        }.join()
        println("Coroutine A is completed")
    }

    delay(2000)
    println("root Coroutine is completed")
}
```
![Coroutine_Exception_Handling_13](/assets/Coroutine_ExceptionHandling_13.PNG)

또한 Async빌더로 생성된 코루틴은Handler를 할당해도 예외에 대한 처리를 해주지 않는다.

```kotlin
val handler = CoroutineExceptionHandler { coroutineContext, throwable ->
    println("$throwable is happened")
}
fun main():Unit = runBlocking {
    val job = CoroutineScope(handler).async {
        println("Coroutine A is started")
        launch {
            throw Exception()
            println("Coroutine Child A is started")
        }.join()
        println("Coroutine A is completed")
    }
    job.await()
    delay(2000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_12](/assets/Coroutine_ExceptionHandling_12.PNG)

예외를 던지자 강제종료되는 모습이다.

```kotlin
fun main():Unit = runBlocking {
    val job = CoroutineScope(Dispatchers.Default).async {
        println("Coroutine A is started")
        launch {
            throw ArithmeticException()
            println("Coroutine Child A is started")
        }.join()
        println("Coroutine A is completed")
    }
    try {
        job.await()
    }catch (e:Exception){
        println("I got $e Exception!!")
    }
    delay(2000)
    println("root Coroutine is completed")
}
```

![Coroutine_Exception_Handling_14](/assets/Coroutine_ExceptionHandling_14.PNG)

async의 경우 사용자의 interaction 에 따라 예외를 처리해줘야 한다. 즉, 사용자의 interaction에 따라 .await()호출을 try-catch문 내부에 작성하여 예외를 별도로 처리해야 한다.

# 끝으로
---
코루틴가이드에 있는 구성요소들을 대략적으로 모두 살펴보았다. 하지만 학습과 활용은 별개의 영역 이라고 생각된다. 물론 기본기가 튼튼한만큼 활용은 잘되겠지만..

토이프로젝트의 추가적인 진행에 지금까지 배운 코루틴을 적용하여 활용해보자

# References
---
https://kotlinlang.org/docs/exception-handling.html#cancellation-and-exceptions
