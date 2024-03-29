---
title: "[Coroutine] 코루틴"
categories:
- Coroutines
tags:
- Study

toc: true
toc_sticky: true
toc_label: "목차"
---

# Kotline Coroutines
---
코틀린의 코루틴은 비동기 스레드를 제공해주는 라이브러리다. 코루틴 이전에는 RxJava 혹은 asyncTast 나 직접 Thread를 생성하고 할당하고 제거하는 과정을 구현해왔다.

하지만 asyncTast의 경우 본질적인 문제점 '액티비티에 종속되지않는다' 때문에 deprecate 되었고, 이후 19년도부터 Coroutine이 소개되면서부터 비동기 스레드 라이브러리로 자리매김 하였다.

현재는 RxJava와 Coroutine을 번갈아가며? 사용하는 추세인것같다. 두가지의 장단점이 명확하기 때문이다.

Coroutine은 사용하기 쉽지만 활용성? 제어? 가 좀 떨어지는 반면, RxJava의경우 사용하긴 어렵지만 코루틴보다 더 확실한 제어를 통한 활용을 할수있다.

필자는 RxJava를 사용해본적이 없기때문에 자세한 설명은 넘어가겠다..

---
# Coroutine 의 필요성
---
코루틴은 비동기 스레드를 좀더 사용자가 편하게 수명주기를 처리하고 사용할수 있게 제공해주는 라이브러리로, 비동기 스레드를 사용하는 이유부터 알아야한다.

클라이언트 상에서 네트워크 통신 작업을 한다고 예를들어보자, 별다른 스레드를 생성해줘서 처리하지않으면 Main 스레드상에서 네트워크 통신을 처리할것이다.

Main 스레드는 UI와 관련된 작업을 수행하고있는데, 네트워크통신과 같은 작업처리에 있어서 상당한 시간소요가 필요한 작업을 같은 Main스레드상에서 처리하려고 하면,  외부통신을 통해 데이터를 주고받아오는 동안 UI는 멈추게 된다. 

또한, UI가 멈추게되면 ANR이 발생할 가능성이 매우높다. 구글에서는 이러한 점을 그냥두지말라고 조언하고있다.(ANR=비정상동작감지로 인한 강제중지)

사용자가 뭔가 버튼을 눌렀을때, 화면이 멈추거나 최악의경우 ANR이 발생하여 앱이 강제종료 된다면 그즉시 삭제할게 틀림없다.

따라서 이를방지하기 위해 네트워크통신 또는 여러 작업에 소요시간이 필요한 경우 Thread를 생성하여 동시에 생성된 다른Thread에서 작업을 처리하도록 함으로써, Main 스레드가 멈추지않도록 할수 있다.

---
# Coroutine 의 사용
---
코루틴은 interface로 정의되어있어 사용자가 원하는 대로 CoroutineContext을 Override 하여, 어느scope상에서 어떤동작을 어디서 수행하고 종료하는지의 생명주기와 예외를 처리할수 있다. 

최상위 scope(범위)인 CoroutineScope 상에서 동작하도록 해야하고, 싱글톤으로 작성되어 application의 라이프사이클 동안 수행되어 별도의 생명주기 처리없이 사용할수있는 globalScope에서 사용할수도 있다. ( globalScope의 경우 재대로 cancel과 exception을 처리해주지않으면 문제가 발생하기 쉽다. 따라서 viewmodelScope 와같은 라이프사이클까지 알아서 처리해주는 녀석들을 사용해야 좀더 안전하다고 한다.)

구글에서는 라이프사이클을 잘 처리하기위해 Coroutine interface를 상속하는 클래스를 만들어 생명주기를 원활히 처리하는것을 권고하고 있다.

CoroutineContext는 4가지로 구성되어있고 다음과같다.

1. Job : Coroutine의 핸들로써 가장중요한 녀석으로, 생명주기를 제어하기위해 사용하는 객체이다. 
2. CoroutineDispatcher : 어떤스레드상에서 동작할것인지를 결정하는 인자다. Dispatcher에는 Main(UI),Default(대용량데이터처리),IO(네트워크통신) 가있다.
3. CoroutineName : 코루틴의 이름으로 default값은 'coroutine'
4. CoroutineExceptionHandler : 예외를처리하기위한 핸들러 ( 코루틴은 내부로직이 취소되면 반드시 예외를 발생시키기 때문에 그에대한 처리가 필요하다.)

각각의 CoroutineContext를 처리하여 개발자가 원하는 흐름대로 코루틴이 수행될수 있도록 구성해야만 한다.

코루틴을 사용하기위해서는 위의 CoroutineContext를 선언하고 CoroutineBuilder를 통해 실행시켜야 한다.

코루틴 builder로는 launch,async,withContext 등등이 존재한다.

1. launch : launch블록은 반환값이 없을때 와 일반함수 내부에서 코루틴블럭을 수행해야할때 적절하다.  그저 선언되고 수행되면 코드에따라 순차적으로 실행된다.
2. async : async블록은 반환값이 잇을때 혹은 launch블록 내부에서 반환값이 필요할때 사용함에 적절하다.  작업도중에 취소가 되어도 await() 을통해 작업완료를 보장할수있다.
3. withContext : withContext는 내부의 블록코드 수행중에 CoroutineContext의 변경(Dispatcher의변경) 이 일어나야할때 반드시 사용하여야 하며, 내부로직이 완전히 수행되면 블록을 빠져나오는 특성이 있기때문에 async의 await()처럼 변수에 할당하여 사용할수 있다.

이외에도 정지함수인 delay()가 존재하는데, 코루틴수행도중 적절한 delay(정지) 가 필요할수도 있다.

CoroutineScope 내부에 여러개의 코루틴이 생성&수행 될수 있고, 단하나만의 코루틴이 생성&수행될수도 있다.

따라서, 개발자가 적절히 코루틴빌더를 통해 원하는대로 생명주기의 흐름에맞게 제어해야함이 필수적이다.