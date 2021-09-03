---
title: "[Android] Service와 Broadcast Receiver"
categories:
- Android
tags:
- Study
---

---

참고서적: Doit 안드로이드 앱 프로그래밍

---

6장은 화면구성없는 앱의구성요소로 백그라운드 역할을 하는 서비스와 글로벌 이벤트를 받아서 처리하는 브로드캐스트 수신자 를 다루며,

앱의 어떤 구성요소들이 추가되었는지를 시스템에 알려주는 manifest,  앱을 build 하거나 배포할때 필요한 Gradle과 그외의 리소스들을 다룬다.

---
# Service
백그라운드 역할을 하는 앱의 구성요소로 intent를 시스템에 전달하여 액티비티를띄우고 데이터전달을 할수있다.

예시로 카카오톡을들자면, 카카오톡의 앱을 실행중이지 않은 상태에서도(다른앱을 실행중이거나 끄고잇을때) 카카오톡 메세지를 받을수있다. 

이와같은 동작은 서비스가 백그라운드에서 실행상태를 유지하며, 앱이 비정상적으로 종료되어도 자동으로 재시작되기 때문이다. 

또한 Service는 앱의구성요소로 manifest에 등록하여 시스템이 알수있게 해야한다.

| 주요메소드 | 설명 | 
|:--------:|:--------:|
| `startService()` | 서비스를 실행시키는 메소드|
| `stopService()` | 서비스를 종료시키는 메소드|
| `onStartCommand()` | 전달받은 intent객체를 처리하는 메소드. 이미 메모리에 만들어져있다면 onCreat()를 호출하지않고 바로 이메소드를 호출함|
| `startActivity()` |액티비티를 실행시키는 메소드|
| `onNewIntent()` | Activity에서 전달받은 intent객체를 처리하는 메소드. 이미 메모리에 만들어져있다면 onCreate() 대신에 바로 이메소드를 호출|

서비스가 서버역할을 하면서 액티비티와 연결될수 있도록 만드는것을 Binding 이라고 한다.
이를 위해서는 onBind()를 재정의 해야한다. 

IntentService클래스는 onHandleIntent() 가 수행된후 종료되는 클래스로 이메소드는 onStartCommand()로 intent가 전달받으면 실행되며, 한번 실행되고 끝나는 작업을 수행할때 사용한다.

이러한 기능들로 서버에 데이터를 요청하고기다리는 네트워킹작업을 서비스로 분리하여 구현하여 보는화면과 상관없이 서버와 통신할수있는 기능을 구현할수있다.

---

# Broadcast Receiver

Broadcasting 은 이벤트를 여러객체에 전달하는것을 뜻한다.

예로들면, '문자가왔습니다', '전화가왔습니다' 와같은 Global Event를 말한다.

이 Broadcasting 의 이벤트를 받기위해서는 내가만든 앱에 Broadcase Recevier를 등록하면 된다.

이또한 역시 앱의 구성요소로 manifest 에 등록하여 시스템이 알수있게 해야한다.

| 주요메소드 | 설명 | 
|:--------:|:--------:|
| `onReceive()` | 원하는 Global event 가 도착하면 자동으로 호출되는 메소드로, 이메소드에서 전달받은 intent객체를 처리한다.|


내가원하는 intent(event)만 받아 처리하기를 원한다면 Intent-Filter 태그를 manifest에 등록해야 한다.

Broadcast Receiver가 등록된 앱의 메인액티비티가 적어도 한번은 실행되어야 Receiver가 event를 받을수 있다.

주의할점으로, 앱A가 실행되지않은 상태에서 Global Event가 도착하면 앱B가 실행되는 도중에 앱A가 실행될수 있다.

이때문에 앱A와 앱B 둘다 같은 이벤트를 받도록 해두면 오류발생시 어느앱이 문제인지 알기어렵다.

따라서, 신버전을 만들면 구버전은 제거하는게 좋다.

---
# Dangerous Permission

사용자가 아무런 생각없이 앱을 다운받아 실행햇을때, 나의 정보가 유출되는것을 방지하기위해 안드로이드에는 위험권한(Dangerous Permission)을 대화상자로 띄워주는 기능이 있다.

기존의 위험권한은 앱의 설치시 부여하도록 했는데, 위와같은 경우들로 인해 실행시에 권한을 부여하도록 변경되었다.

대표적인 위험권한들은 위치,카메라,마이크,연락처,전화,문자,일정,센서 들이 있고 그에따른 세부권한들이 있다.

또한, SD카드에 접근하는것 역시 위험권한으로 READ_EXTERNAL_STORAGE (읽기권한)와 WRITE_EXTERNAL_STORAGE (쓰기권한)이다.

위험권한을 설정하는법은 두가지이다.

---

### 기본적인 위험권한 부여하기 
위험권한을 등록하기 위해서는 manifest에 < user-permission > 태그를 이용하여 설정해주고, 
Activity  내에서 manifest에 등록한 위험권한들을 변수에 할당한후에, 
ActivityCompat 에 있는 requestPermissions() 메소드를 호출하여 위험권한을 요청하는 대화상자를 띄울수있다.
	
이메소드는 호출되고난후 수락되었는지 거부되었는지 알수없기때문에 콜백메소드를 따로 만들어 결과를 처리하는것도 필요하다.
	
콜백메소드는 onRequestPermissionsResult() 메소드를 재정의하여 구현한다.

### 외부라이브러리로 위험권한 부여하기

외부라이브러리는 Gradle에 추가해야한다.

module 수준의 Gradle에 dependencies 블록에 implementation 을 추가하고, allproject{ repositories{ maven { url }}}} 을 추가한다.

후에 Sync Project with Gradle Files 아이콘을 눌러 변경사항을 적용시킨다.

그후 Activity.java 파일에서 main activity클래스를 AutoPermissionsListener 클래스를 상속받도록하고 onCreate()에서 자동으로 권한을 부여하는 loadAllpermissions() 메소드를 호출한다. 

그후 권한부여 요청결과가 넘어오면  onRequestPermissionsResult() 로 전달받게되고, 이메소드를 재정의하여 parsePermissions()로 권한부여결과가 승인 또는 거부 인지 나누어 onGranted() 또는 onDenied() 메소드가 호출되도록 한다.

이후 각각의 메소드를 재정의하여 승인 또는 거부되었음을 처리한다.


이두가지 방법으로 위험권한을 부여할수있다.

---
# Resource와 manifest

안드로이드 앱은 크게 앱의흐름과 기능을 정의하는 자바코드와 레이아웃이나 이미지와같은 사용자에게 보여지는 리소스로 구성된다.

리소스는 /app/res 하위에 구성하며 /app/assets 역시 리소스이다.

/app/res 하위에 구성되는 리소스는 빌드되어 설치파일에 추가되지만 /app/assets하위에 구성되는 리소스는 빌드되지 않는다.

하위폴더로 구성되는 각각의 폴더들은 각각의 사용에맞게 문자열이나 기본데이터 타입들은 values폴더에, 이미지와같은 것들은 drawable 폴더에 등등 구성되어 유지관리 가 편하다는 장점이있다.

manifest는 앱의구성요소들이 어떤것들이 포함됫는지, 어떤 권한들이 부여됫는지, 어떤라이브러리가 포함됫는지 등등을 시스템에 알려주기때문에 중요하다.

---
# Gradle

Gradle은 안드로이드 스튜디오에서 사용하는 빌드 및 배포도구이다.

이들은 소스파일이나 리소스파일을 빌드하거나 배포할때 사용한다.

빌드설정은 Build.gradle 파일에 넣어 관리하는데, 프로젝트 수준과 모듈수준 두개로 나누어 관리한다.

프로젝트 수준의 gradle은 거의 수정될일 이없고, 외부도구를 포함시키기위해 dependencies 안에 classpath를 수정하는 정도는 가끔잇을수있다.

모듈수준의 gradle 중 중요한것들을 몇개나열하면,

1. applicationId: 앱의 고유id값, 전세계에서 고유한 값으로 설정되어야 한다.
2. compileSdkVersion: 빌드시 Sdk의 어떤버전을 사용하는것인지 지정
3. minSdkVersion: 최소의 Sdk버전을 지정
4. targetSdkVersion: 검증된버전을 지정
5. dependencies: 외부라이브러리 추가할때 사용

그외에  local.properties에는 현재사용하는 pc에 설치된 Sdk 위치가 기록되있고, gradle.properties에는 메모리설정이 들어있다.

그리고 gradle-wrapper.properties에는 Gradle 버전정보 등이 있다. 

모든 예재소스코드는 [깃허브주소](https://github.com/jowunnal/studyAndroid "github link") 에 있다.
