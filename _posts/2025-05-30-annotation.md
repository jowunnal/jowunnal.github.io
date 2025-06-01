---
title: "[Kotlin] Annotation 생성 및 활용 방법"
categories:
- Kotlin
tags:
- Study

toc: true
toc_sticky: true
toc_label: 목차
---

보통 어떤 기능을 만들기 위해 클래스나 인터페이스를 생성하고, 프로퍼티와 함수를 구현하고 이용합니다. 이렇게 생성된 클래스의 프로퍼티나 함수를 이용하여 캡슐화된 특정 기능을 호출 및 참조할 수 있습니다.

만약, 만들어진 기능이나 클래스 또는 인터페이스에 대해 추가적인 어떤 기능을 실행하려면 어떻게 해야 할까요? 단순히 확장함수나 위임 객체를 생성하여 기능을 추가적으로 확장하는 형태로 가져갈 수도 있을겁니다. 하지만 그 행위가 여러 클래스나 인터페이스에 대해 반복적으로 실행된다면 어떨까요?

선언 및 호출이 여러 번 반복된다면 보일러플레이트가 되지 않도록 하기 위한 방법을 강구해야 합니다. 이런 경우 특정 클래스나 인터페이스 혹은 프로퍼티나 함수에 어노테이션을 작성하고 적절한 시간(Compile Time 혹은 Runtime)에 약속된 기능을 실행시키는 작업을 단순화시킬 수 있습니다.

이번 포스팅에서는 Kotlin 에서 Annotation 을 선언하는 방법을 알아보고, 적절한 시간(Compile Time 혹은 Runtime) 에 약속된 기능을 실행시킴으로써 보일러 플레이트를 줄이는 방법에 대해 정리해보려 합니다.

# Annotation

어노테이션은 코틀린 파일과 같은 넓은 범위에서 부터 특정 클래스의 프로퍼티의 getter 나 setter 와 같은 좁은 범위까지에 대해 약속된 동작을 호출 및 실행시킬 수 있도록 마킹하는 방법입니다.

코틀린에서는 어노테이션이 참조하고자 하는 대상에 대해 정확하게 지정할 수 있습니다. 이를 __사용 지점 타깃__ 이라고 합니다. 사용 지점 타깃으로는 파일(file), 프로퍼티(property), 필드(field), 프로퍼티의 getter(get) 와 setter(set) 함수, 수신 객체(receiver), 생성자 파라미터(param), 위임 필드(delegate) 가 존재하며, 어노테이션을 특정 동작에 지정할 수 있습니다. 파일을 대상으로 한다면, @JvmName 을 예시로 들었을 때,  ```@file: JvmName("myFile")``` 와 같이 package 선언보다 이전에 작성함으로써 해당 파일을 @JvmName 으로 마킹할 수 있습니다.

어노테이션은 @JvmName 과 같이 언어 수준에서 미리 생성된 것들이 존재하며, 개발자가 직접 생성할 수도 있습니다.

## Annotation class

어노테이션은 class 라는 키워드가 붙은 일종의 클래스 입니다. 다만, 본문이 없으며 primary constructor 만이 존재하는 클래스 입니다.

```kotlin
annotation class JvmName(val name: String)
```

어노테이션의 클래스의 주생성자에 존재하는 파라미터들은 반드시 val 로 선언되야 하며, primitive type, string, 다른 클래스나 인터페이스, enum 과 같은 타입이 될 수 있습니다. 뿐만 아니라 어노테이션 클래스와 프로퍼티들에는 메타 어노테이션으로 마킹될 수 있습니다.

### Meta Annotation

메타 어노테이션은 어노테이션의 어노테이션 입니다. 즉, 어노테이션에 마킹되는 특수한 어노테이션 입니다. 가장 기본적으로 언어 수준에서 지원하는 메타 어노테이션으로 다음 4가지가 존재합니다.

#### @Target

@Target 메타 어노테이션은 해당 어노테이션이 어떤 요소에 마킹 될 수 있는지 를 표시하기 위해 사용합니다. 

```kotlin
package kotlin.annotation

@Target(AnnotationTarget.ANNOTATION_CLASS)
@MustBeDocumented
public annotation class Target(vararg val allowedTargets: AnnotationTarget)

public enum class AnnotationTarget {
    CLASS,
    ANNOTATION_CLASS,
    TYPE_PARAMETER,
    PROPERTY,
    FIELD,
    LOCAL_VARIABLE,
    VALUE_PARAMETER,
    CONSTRUCTOR,
    FUNCTION,
    PROPERTY_GETTER,
    PROPERTY_SETTER,
    TYPE,
    EXPRESSION,
    FILE,
    @SinceKotlin("1.1")
    TYPEALIAS
}
```

지정 가능한 요소들은 CLASS(클래스), ANNOTATION_CLASS(어노테이션 클래스), FUNCTION(함수), TYPE_PARAMETER(제네릭의 타입 파라미터), FIELD(프로퍼티의 backing field), LOCAL_VARIABLE(지역 변수), VALUE_PARAMETER(생성자 파라미터 혹은 함수 파라미터), CONSTRUCTOR(생성자), PROPERTY(프로퍼티), PROPERTY_GETTER(프로퍼티의 getter 함수), PROPERTY_SETTER(프로퍼티의 setter 함수), TYPE(타입), TYPE_ALIAS(typealias), FILE(파일), EXPRESSION(if else 문과 같은 표현식) 이 존재합니다.

```kotlin
@Target(AnnotationTarget.ANNOTATION_CLASS)
annotation class MyTest(val name: String = "test")

@MyTest
annotation class TestA(val a: String)
```

해당 예시처럼 @Target 이 ANNOTATION_CLASS 로 작성된 @MyTest 어노테이션은 다른 어노테이션 클래스에만 작성될 수 있습니다. 또한 @Target 은 한개 이상으로도 선언할 수 있습니다.

```kotlin
@Target(AnnotationTarget.ANNOTATION_CLASS, AnnotationTarget.CLASS)
annotation class MyTest(val name: String = "test")

@MyTest
annotation class TestA(val a: String)
```

만약 @Target 을 지정하지 않은 경우에는 (CLASS,  PROPERTY, PROPERTY_GETTER, PROPERTY_SETTER,  FIELD,  LOCAL_VARIABLE, VALUE_PARAMETER,  CONSTRUCTOR, FUNCTION) 이 기본값으로 지정됩니다.

#### Repeatable

@Repeatable 은 해당 메타 어노테이션을 특정 어노테이션에 반복적으로 선언할 수 있는지를 나타냅니다. @Repeatable 이 마킹되어 있다면 해당 어노테이션을 같은 요소에 반복해서 마킹할 수 있습니다.

```kotlin
package kotlin.annotation

@Target(AnnotationTarget.ANNOTATION_CLASS)
public annotation class Repeatable
```

```kotlin
@Target(AnnotationTarget.ANNOTATION_CLASS, AnnotationTarget.CLASS)
@Repeatable
annotation class MyTest(val name: String = "test")

@MyTest(name = "a")
@MyTest(name = "b")
annotation class TestA(val a: String)
```

기본적으로 @Repeatable 을 선언하지 않는다면 해당 어노테이션은 한번만 선언 가능합니다.

#### MustBeDocumented

@MustBeDocumented 는 Generated Documentation 에 해당 어노테이션이 포함되어야 하는 경우 선언하는 메타 어노테이션 입니다. 

```kotlin
package kotlin.annotation

@Target(AnnotationTarget.ANNOTATION_CLASS)
public annotation class MustBeDocumented
```

기본적으로 @MustBeDocumented 을 선언하지 않는다면 Generated Documentation 에 포함되지 않습니다.

#### Retention

@Retention 은 어노테이션의 유효 범위를 나타내는 메타 어노테이션 입니다. 해당 어노테이션의 프로퍼티의 타입은 AnnotationRetention 이라는 enum 타입이며, 종류로는 3가지가 존재합니다.

```kotlin
public enum class AnnotationRetention {
    SOURCE,
    BINARY,
    RUNTIME
}

@Target(AnnotationTarget.ANNOTATION_CLASS)
public annotation class Retention(val value: AnnotationRetention = AnnotationRetention.RUNTIME)
```

1. source: 소스코드에만 존재하며, 컴파일 타임에 제거됩니다.
2. binary: 컴파일 타임까지 존재하며, 런타임에 제거됩니다.
3. runtime: 런타임까지 존재합니다.

@Retention 을 명시하지 않은 경우 코틀린에서 기본값은 runtime 이 되게 됩니다. runtime 의 경우 해당 메타 어노테이션이 작성된 요소에 대해 reflection 을 수행하여 약속된 기능을 수행시키는 사용 사례입니다. 또한, binary 의 경우 kapt 나 ksp 라는 코틀린 컴파일러 플러그인을 사용하여 컴파일 타임에 어노테이션에 대해 미리 정의된 코드를 생성해주는 사용 사례가 됩니다.

어노테이션 클래스 자체는 본문이 없고 특별한 기능이 있지 않아 추가적인 작업이 필요합니다. 그리고 그 목적에 따라 작성한 어노테이션 클래스 선언에 정확한 @Retention 과 @Target 과 같은 위의 메타 어노테이션들을 설정해 주어야 합니다.

# Reflection

선언된 어노테이션을 런타임에 활용하는 방법은 Reflection 을 활용하는 것 입니다. Reflection 은 실행 시간에 동적으로 클래스의 정보를 JVM 메모리 내에서 검색하여 가져오는 기능입니다. 코틀린에서 `kotlin.reflect.full` 의 api 들을 이용하여 런타임에 참조된 클래스의 정보를 가져온 뒤, `hasAnnotation()` 이나 `findAnnotation()` 으로 특정 어노테이션이 마킹되었는지 확인합니다. 그리고 특정 어노테이션이 있는 경우, 특정 기능을 수행하는 함수를 만들어 호출함으로써 런타임에 어노테이션을 활용할 수 있습니다.

Reflection 에서 어노테이션을 활용한다면, 어노테이션의 Retention 범위를 runtime 으로 선언해야 합니다.(Default 값이 runtime 이므로 생략해도 무방합니다.) 그렇지 않으면 어노테이션이 런타임에 사라지기 때문에 오류가 발생합니다.

Reflection 을 이용하여 어노테이션을 활용하는 사례는 굉장히 많습니다. 대표적으로 Moshi 나 Gson 같은 직렬화 라이브러리에서도 사용될 수 있으며, Retrofit2 의 원격 API 를 위한 엔드 포인트들을 모아놓은 인터페이스를 인스턴스화 하기 위한 java.lang.reflect#Proxy 도 이에 해당합니다.

# Annotation Processing

Annotation Processing 은 Compiler Plugin 을 활용하여 Compile Time 에 선언된 어노테이션을 기반으로 코드를 생성하는 방법입니다. 대표적으로 kapt 와 ksp 를 활용할 수 있는데요. kapt 의 경우 자바의 어노테이션 프로세서를 활용하여 compile time 에 특정 코드를 추가하는 컴파일러 플러그인이고, ksp 는 코틀린 컴파일러의 IR 변환 과정에 직접 개입하는 경량화된 컴파일러 플러그인의 일종으로 kapt 보다 효율적으로 동작합니다.

## Kapt vs Ksp

어노테이션으로 마킹된 요소에 대해 컴파일 타임에 코드를 생성해주기 위해서는 가장 기본적인 방법으로 자바의 Annotation Processor 를 이용하는 것 입니다. 자바의 어노테이션 프로세서를 활용하기 위해서 간단하게 kapt(Kotlin Annotation Processing Tool) 코틀린 컴파일러 플러그인을 사용할 수 있습니다.

Kapt 는 자바 컴파일러를 기반으로 동작하며, 자바의 Annotation Processor 를 활용하기 때문에 코틀린만의 문법인 프로퍼티, 확장함수 와 같은 것들을 사용할 수 없습니다. 또한, 코틀린 코드에 대해 자바 어노테이션 프로세서가 이해할 수 있도록 Java Stub 을 생성해야 하는데, 해당 과정에서의 오버헤드로 인해 빌드 타임을 늘려 느리다는 문제가 있었습니다.

이러한 문제들을 해결하기 위해 코틀린 수준에서 어노테이션 프로세싱을 지원하는 ksp(Kotlin Symbol Processing) 를 구글에서 지원하기 시작했습니다. ksp 는 코틀린 컴파일러 플러그인의 경량화 버전으로 kotlin compiler 의 IR 변환에 직접 개입하여 코드를 생성하는 즉, 컴파일러의 프론트 엔드 단계를 개발자가 확장할 수 있는 기능을 제공합니다. 또한 기존의 kapt 보다 우수한 성능을 보여줘 빌드 타임 감소에 도움을 줄 수 있습니다. ksp 출시 이후부터 kapt 는 deprecated 되었으며 dagger, room 과 같이 기존에 kapt 를 활용하던 라이브러리들도 모두 ksp 를 지원하고, 전환하는 것을 권장하고 있습니다.

코틀린 컴파일러의 아키텍처와 코틀린 컴파일러 플러그인에 관한 자세한 내용은 [포스팅](https://nativeblocks.io/blog/extending-kotlin-compiler-with-ksp/ "link") 을 참고하시면 도움이 될 것 같습니다.

컴파일 타임에 어노테이션을 활용하는 경우 어노테이션의 Retention 범위를 binary 로 선언해야 합니다. 불필요하게 runtime 으로 선언한다면, 실행 시점에 불필요하게 메모리의 공간을 차지하게 되므로 컴파일 타임에서만 사용하는 어노테이션에 대해서는 binary 로 선언해야 합니다.

## Reflection vs Annotation Processing

Reflection 은 런타임에 동적으로 클래스에 대한 정보를 가져오기 때문에 성능적 오버헤드가 발생합니다만, 원하는 클래스에 대한 정보를 참조할 수 있다는 유연성을 가집니다.

이에 비해 Annotation Processing 은 컴파일 과정에 컴파일러의 프론트 엔드 단계에 직접 개입하여 어노테이션이 작성된 요소들에 추가적인 코드를 생성하기 때문에 빌드 타임을 증가시키거나 전체 파일의 크기를 좀 늘릴 수 있으며, 이미 정해져 있다는 점에서 유연하지 않다는 단점이 있습니다. 하지만 Reflection 이 발생하지 않으므로 성능적 오버헤드를 줄일 수 있습니다.

현재 이러한 장단점 속에서 많은 라이브러리에서는 Annotation Processing 방법을 이용하여 어노테이션을 처리하고 있습니다. Jetpack 에 포함된 Room, Hilt, DataStore 과 같은 라이브러리들이 대표적 사례입니다. 어노테이션을 Reflection 으로 처리한다면, 실행 시점에 퍼포먼스의 이슈를 생성하게 됩니다. 이는 결과적으로 실제로 사용하는 사용자들에게 영향을 끼치기 때문에 사용자 경험을 나쁘게 만들 수 있습니다.

하지만 Annotation Processing 은 빌드 타임을 늘리거나 유연성을 떨어뜨릴 수 있지만, 사용자가 아닌 개발자에게 영향을 끼친다는 점에서 이것은 개발자가 풀어야 할 이슈이기 때문에 보통의 경우에서 이 방법을 선택합니다.