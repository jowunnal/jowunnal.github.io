---
title: "[Kotlin] Annotation"
categories:
- Kotlin
tags:
- Study

toc: true
toc_sticky: true
toc_label: 목차
---

보통 어떤 기능을 만들기 위해 클래스나 인터페이스를 생성하고, 프로퍼티와 함수를 구현하고 이용합니다. 이렇게 생성된 클래스의 프로퍼티나 함수를 이용하여 캡슐화된 특정 기능을 여러 번 반복하여 생성하지 않고 호출 및 참조할 수 있습니다.

만약, 클래스나 인터페이스에 대해 혹은 특정 프로퍼티나 함수에 대해 추가적인 어떤 기능을 실행하려면 어떻게 해야 할까요? 단순히 확장함수나 위임 객체를 생성하여 기능을 추가적으로 확장하는 형태로 가져갈 수도 있을겁니다. 하지만 그 행위가 여러 클래스나 인터페이스에 대해 반복적으로 실행된다면 어떨까요?

선언 및 호출이 여러 번 반복된다면 보일러플레이트가 되지 않도록 하기 위한 방법을 강구해야 합니다. 이런 경우 특정 클래스나 인터페이스 혹은 프로퍼티나 함수에 어노테이션을 작성하고 적절한 시간(Compile Time 혹은 Runtime)에 약속된 기능을 실행시키도록 만들 수 있습니다.

이번 포스팅에서는 Kotlin 에서 Annotation 을 선언하고, 반복적으로 해당 기능을 호출하지 않으면서, 이를 Compile Time 혹은 Runtime 에 어노테이션으로 마킹하는 간단한 행위로써 약속된 기능을 호출 및 실행시키는 방법에 대해 정리해보려 합니다.

# Annotation

어노테이션은 코틀린 파일과 같은 넓은 범위에서 부터 특정 클래스의 프로퍼티의 getter 나 setter 와 같은 좁은 범위까지에 대해 약속된 동작을 호출 및 실행시킬 수 있도록 마킹하는 방법입니다.

코틀린에서는 어노테이션이 참조하고자 하는 대상에 대해 정확하게 지정할 수 있습니다. 이를 __사용 지점 타깃__ 이라고 합니다. 사용 지점 타깃으로는 파일(file), 프로퍼티(property), 필드(field), 프로퍼티의 getter(get) 와 setter(set) 함수, 수신 객체(receiver), 생성자 파라미터(param), 위임 필드(delegate) 가 존재하며, 어노테이션을 특정 동작에 지정할 수 있습니다. 파일을 대상으로 한다면, @JvmName 을 예시로 들었을 때,  ```@file: JvmName("myFile")``` 와 같이 package 선언보다 이전에 작성함으로써 해당 파일을 @JvmName 으로 마킹할 수 있습니다.

어노테이션은 @JvmName 과 같이 언어 수준에서 미리 생성된 것들이 존재하며, 개발자가 직접 생성할 수도 있습니다.

## Annotation class

어노테이션은 class 라는 키워드가 붙은 일종의 클래스 입니다. 다만, 본문이 없으며 primary constructor 만이 존재하는 클래스 입니다.

```kotlin
annotation class JvmName(val name: String)
```

어노테이션의 클래스의 주생성자에 존재하는 파라미터들은 반드시 val 로 선언되야 하며, primitive type, string, 다른 클래스나 인터페이스 혹은 다른 어노테이션 클래스(메타 어노테이션) 타입이 될 수 있습니다. 

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

@Retention 을 명시하지 않은 경우 코틀린에서 기본값은 runtime 이 되게 됩니다. runtime 의 경우 해당 메타 어노테이션이 작성된 요소에 대해 reflection 을 수행하여 약속된 기능을 수행시키기 위해 사용합니다. binary 의 경우 kapt 나 ksp 이 대표적 예시인데, kapt 의 경우 자바의 어노테이션 프로세서를 활용하여 compile time 에 특정 코드를 추가하는 방법이고, ksp 는 코틀린 컴파일러의 IR 변환 과정에 직접 개입하는 경량화된 컴파일러 플러그인의 일종으로 특정 코드를 kapt 보다 효율적으로 추가하는 방법 입니다. 

AnnotationRetention.RUNTIME 과 AnnotationRetention.BINARY 의 동작 방식의 차이점은 아래에서 더 살펴보도록 할 것이며, 특히 binary 의 kapt 와 ksp 의 코드 생성 및 변환 과정에서 의 차이점은 지금 시점에서 한번 살펴볼 가치가 충분합니다.

### Kapt vs Ksp

어노테이션으로 마킹된 요소에 대해 컴파일 타임에 코드를 생성해주기 위해서는 가장 기본적인 방법으로 자바의 Annotation Processor 를 이용하는 것 입니다. 자바의 어노테이션 프로세서를 활용하기 위해서 간단하게 kapt(Kotlin Annotation Processing Tool) 코틀린 컴파일러 플러그인을 사용할 수 있습니다.

Kapt 는 코틀린 코드를 자바 코드로 변환하고, 자바의 Annotation Processor 를 활용하기 때문에 코틀린만의 문법인 프로퍼티, 확장함수 와 같은 것들을 사용할 수 없습니다. 또한, 그 과정에서의 오버헤드가 발생하여 느리다는 단점이 존재합니다.

이러한 문제들을 해결하기 위해 코틀린 수준에서 어노테이션을 지원하는 ksp(Kotlin Symbol Processing) 를 구글에서 지원하기 시작했습니다. ksp 는 코틀린 컴파일러 플러그인의 경량화 버전으로 kotlin compiler 의 IR 변환에 직접 개입하여 코드를 생성하는 즉, 컴파일러의 프론트 엔드 단계를 개발자가 확장할 수 있는 기능을 제공합니다. 또한 기존의 kapt 보다 우수한 성능을 보여줘 빌드 타임 감소에 도움을 줄 수 있습니다. ksp 출시 이후부터 kapt 는 deprecated 되었으며 dagger, room 과 같이 기존에 kapt 를 활용하던 라이브러리들도 모두 ksp 를 지원하고, 전환하는 것을 권장하고 있습니다.

자세한 내용은 이 [포스팅](https://nativeblocks.io/blog/extending-kotlin-compiler-with-ksp/ "link") 을 참고하시면 도움이 될 것 같습니다.