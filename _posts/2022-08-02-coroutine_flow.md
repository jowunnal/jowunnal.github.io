---
title: "[Coroutine] Flow"
categories:
- Coroutines
tags:
- Study
---

Jetbrains의 Coroutine Flow의 docs 개요는 이렇게 시작한다.

>'A suspending function asynchronously returns a single value, but how can we return multiple asynchronously computed values? This is where Kotlin Flows come in.'

코루틴의 flow는 비동기적으로 다수의 계산된 값들을 어떻게 return 받을것인가? 로부터 코루틴이 시작되었다고 한다.

# Reactive
---
코루틴의 flow를 이해하기전에, 여러 다수의 블로그들에서는 반응형 프로그래밍부터 설명을 한다.

반응형 프로그래밍은 다양한 개발자들 마다 정의가 다 다르다...

하지만 공통적으로 명시하는 말은 publisher(발행자)와 observer(구독자) 사이에서 발생하는 데이터들을 스트림에 담아두고, 연속적인 데이터스트림 상의 데이터가 변경되었을때 변경사항에 대해 끊임없이 상호작용 해나가는 부분은 동일하다.
 
 즉, UI 가 존재하는 곳에서 꽃을 피우는 프로그래밍 기법 이라고 한다.

사용자가 화면을 터치하고, 클릭하고, 그에따라 다른화면을 띄운다던지 하는 일종의 사용자의 행동에따라 반응하여 UI의 내용의 수정을 만들어줄때, 기존의 명령형 프로그래밍을 하게되면 boiler plate가 엄청나게 발생한다.

예를들면, 버튼을 클릭했을때 내장DB의 값이 표현되는 화면내의 TextView의 값을 0에서 1씩 증가하는 코드라고 생각해보자.

```kotlin
button.setOnClickListener{
	val text= Integer.parseInt(textView.text.toString())
	text+=1
	repository.addValue(text)
	textView.text=repository.getValue()
}
```

위와같이 화면내의 값에다가 1을증가시켜 변수에할당하고, 그변수값을 로컬 데이터베이스에 저장하고, 저장된값을 화면내에 다시표시하는 갱신작업을 모두 작성해야만 한다.

만약, 버튼이 여러개라면 이작업을 여러번 반복해야만 한다. 그렇게되면 boiler plate가 엄청나게 발생하는 것이다.

하지만, 반응형프로그래밍 으로 작성하면 코드가 다소 간결해진다.

```kotlin
button.setOnclickListener{
	val text= Integer.parseInt(textView.text.toString())
	text+=1
	repository.addValue(text)
}

button2.setOnclickListener{... etc}

button3.setOnclickListener{... etc}

button4.setOnclickListener{... etc}

repository.value.observe(viewLifecycleOwner, Observer{
		textView.text=it.toString()
		}
)
```

위코드와 같이 버튼이 눌렷을때 값만 변경해주면 Observer가 로컬 데이터베이스의 내용의 변경사항이 감지되면, 데이터의 값을 가져오게되고 it으로 받아 내부코드로직을 수행하여 textView의 값을 자동으로 변경시켜 준다.

그렇게되면 버튼이 여러개여도 클릭리스너만 구현해두면 값을 갱신하는 코드에서는 boiler plate가 줄어드는 모습을 볼수있다.


# Coroutine Flow
---
Flow는 Sequential(연속적인) 데이터 스트림속에 데이터들을 FlowBuilder인 flow{ } 내부에 emit()을통해 넣어두고, collect()를통해 가져오는 방식으로 사용한다. 또한, flowOf()나 .asFlow() 도 마찬가지로 flowBuilder 이며, suspend 확장자가 붙지않지만 suspend함수가 내부에 삽입될수 있는 특징을 가지고 있다.

```kotlin
fun setFlow() = flow{ // flowBuilder
	for(i in 1..3){
		delay(100) // suspend함수가 삽입
		emit(i) // emit()을 통해 스트림에 값을 방출
	}
}

fun main(){
	runBlocking{//Main Thread차단을 방지하기위한 코루틴스쿠프
		setFlow().collect{ value -> println(value)} // collect{}로 스트림상의 데이터를 가져와서 출력
	}
}	
```

데이터스트림에 값을 emit하고 지연을 발생시킨후 코루틴스쿠프 상에서 값을 가져와 출력하는 코드의 예시와같이 사용할수 있다.

### 중간연산자
---
데이터스트림속의 데이터들을 변환하는 중간연산자들도 사용할수있다. map,filer,transform,take() 등등의 연산자들을 통해 스트림에 있는 데이터들을 변환하여 가져올수 있다.

```kotlin
fun main(){
	runBlocking{
		(1..3).asFlow().map{ value -> mappingValue(value) }.collect{ data -> println(data) }
}

suspend fun mappingValue(value : Int):String {
	delay(100)
	return "Type is Changed : $value"
}
```

위와같이 mappingValue 함수를통해 값을 Int타입에서 String타입으로 변환한뒤 뽑아내는 방식으로 emit()과 collect{} 사이에 중간연산자를 수행하여 변환하는 과정을 거칠수 있다.


### 오래걸리는 작업처리
---
스트림에 방출하는 emit()처리에서 1초가 걸리는 반면, 스트림에서 가져오는 collect{} 처리에서 3초가 걸린다고 가정해보자.

데이터 하나를 가져와서 화면에 뿌려주는데 4초가 걸리는 아주아주 오래걸리는 작업이 될것이다. 즉 각각 4초가 걸리므로 1~10을 연산한다면, 40초가 걸린다.

이를 효율적으로 더빠르게 처리시켜주기위해 buffer() 를 사용하면, 파이프라인 작업을 통해서 emit()에 대한 지연시간을 첫번째 데이터에 한해서만 발생하고, 이후의 데이터에 대해서는 영향을 받지 않도록 구현할수 있다.

```kotlin
fun setValue() = flow{
	for(i in 1...10){
		delay(1000)
		emit(i)
	}
}

fun main() = runBlocking{
	setValue().buffer().collect{ value ->
		delay(3000)
		println(value)
	}
}
```

처리결과에서는, 1~10까지의 숫자를 emit()하는부분과 collect{}하는 부분이 파이프라인 동작으로 수행되어 1,2,3 을 emit()하고 1을 collect{}한뒤, 4,5,6을 emit()하고 2를 collect{}하는 방식으로 동작하여 emit()은 첫번째 데이터 지연만 발생하고 이후의 지연은 영향을 받지않아 좀더 효율적으로 동작하도록 개선할수 있다. 

따라서 40초에서 31초만큼으로 개선이 가능한 것이다.

만약, 이렇게 오래걸리는 작업처리 도중에 사용자가 데이터의 변경을 요구해서 변경된 데이터를 받기도전에 다시 변경하여 갱신하여야 하는 경우에 대해서는 어떡할까?

.conflate() 연산자는 첫번째 emit() value를 처리하는동안 뒤의  처리시점에서 가장 최신의 데이터만을 collect{}한다.

따라서 첫번째 데이터와 가장마지막 데이터만을 collect{}하도록 만드는 중간연산자 이다. 하지만 이방법은 결국은 모든연산을 처리하기때문에 연산의 소요시간은 똑같아서 중간에 사용자가 데이터변경을 요구하여 갱신될때 갱신하기전의 데이터처리 소요시간이 엄청나게 오래걸린다면, 갱신되는 데이터가 화면에 나타날때까지 오래걸릴것이다.

이를 개선하기위해서는 collect{} 대신에 .collectLatest{}를 사용한다.

collectLastest{}는 첫번째 emit() value를 처리하다가 그다음 데이터가 들어오면 첫번째 value의 처리로직을 cancel(취소) 한뒤, 두번째 데이터를 처리한다.

따라서, 앞의데이터의 연산결과가 나오기전에 다음데이터에 대한 연산결과가 요구되엇을때 바로 취소후 다음데이터 연산을 하기때문에 소요시간 단축이 가능해진다.

반면에, 위의 경우가 아니라 중간의 데이터가 나타나도록 해야하는 경우가 있다면 conflate()를 사용하여야 한다.
