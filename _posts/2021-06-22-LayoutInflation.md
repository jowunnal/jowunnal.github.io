---
title: "[Android] Layout Inflation"
categories:
- Android
tags:
- Study
---

---

참고서적: Doit 안드로이드 앱 프로그래밍

---

Layout Inflation 이란?
---
앞서공부했던 1,2,3 장과달리 4장은 좀더 메모리에서 동작하는 과정에 다가간 챕터이다.

Layout Inflation은 레이아웃의 전환 즉, 화면의 전개를 통칭한다.

그중 Inflation 이라는것을 이해해야한다. Inflation이란 내가만든 화면구성을하는 Layout이 메모리상에 올라가 객체화되는 과정을 뜻한다.

이 Inflation은 액티비티 java 파일에서 setContentView()메소드가 호출될때 이루어진다는점을 유의해야 한다.

즉, setContentView() 메소드가 호출되기 전에는 메모리상에 inflation이 되어있지 않기 때문에 xml구성요소인 뷰객체들을 할당하거나 이용하게되면 앱이 강제중지되는 오류가 발생하니 유의하자.

내가만든 화면에서 다른화면을 부분적으로 띄우던가 or 다른화면으로의 전환이 일어날때는 어떻게 될까?

내가만든화면을 A 라고하고, 다른화면을 B라고 한다면,

A화면이 메모리상에 Inflation 되고,  메모리상에 없어진뒤 B화면이 메모리상에 inflation 되게 된다.

그렇다면 문제점이 발생한다.

A화면상에 구성했던 데이터들이 메모리상에서 제거되기때문에 소멸된다는 문제점이다.

이것을 처리하기위해 사용하는 방법이 두가지다.

1. onSaveInstanceState() 와 onRestoreInstanceState() 를 override 하여 데이터저장&복원
2. onStop()과 onPause() 를 override 하여 ShardPreferences 클래스 사용하여 데이터저장&복원

Life Cycle
---

결론적으로는 LifeCycle 을 이용하여 원래의 데이터를 저장하고 복원하는 방법을 이용한다.

그렇다면 LifeCycle부터 이해해야 한다. LifeCycle은 이전글에서도 말햇듯이 Developers에 가면 정확하고 디테일하게 알아볼수있다.

공부한내용을 복습하자면,  먼저 3가지의 액티비티 상태정보를 알아야한다.

1. Running : 액티비티가 화면상에 보이는 상태로, 액티비티스택의 최상위에있는 Focus를 받는상태
2. Paused: 일부가 가려져서, Focus를 받지못하는 상태
3. Stopped: 전체가 가려진 상태

이상태정보들에 해당하는 상태로 가기 직전에는 항상 여러 생명주기를 이루는 메소드들이 호출된다. 그과정을 보자면,

New Activity가 메모리상에 Inflation 되면 3가지의 메소드가 순차적으로 실행된다.

1. onCreate() : 액티비티 생성시 호출되며, 화면에 보이는 View 들의 일반적인 상태를 설정하는 부분. Bundle객체로 이전상태 복원가능
2. onStart(): onCreate()이후 항상 호출되는 메소드. 이메소드가 실행되면 항상 바로 onResume()이 호출됨
3. onResume(): 사용자와 액티비티가 상호작용하기 직전에 호출됨. 즉 포커스를 받는 상태이기 직전에 호출(Running직전)

Running 상태에서 다른 액티비티가 호출되어 원래의 액티비티를 일부 가리면 Paused 상태가되며,
이상태가 되기 직전에 onPause()가 호출된다.

이후에 바로 다른액티비티가 메모리상에 제거되고 focus를 받는상태가 된다면, 직전에 OnResume()이 호출된다.

혹은 다른액티비에 의해 완전히 가려지면 onStop()이 호출되고, 다시 focus를 받는상태가 된다면, 직전에 3개의 메소드가 호출된다.

1. onRestart()
2. onStart()
3. onResume()

만약, 원래의 액티비티에서 다른액티비티가 완전히 가리는것이 일부가 가려지지않고 바로 이루어진다면, onPause()와 onStop()이 연속해서 호출된다.

이후 메모리에서 완전히 제거되면 onDestory()가 호출된다.


데이터 저장&복원
---
데이터를 저장하고 복원하는 방법은 위에서 말햇듯이 두가지이다.(공부한것은 두가지이지만 더있을수있다,)

첫번째경우는, onSaveIntstanceState() 에서 bundle객체에 put자료형() 을통해 데이터를 저장하고, getstring()을 통해 데이터를 복원하면 된다.

두번째경우는, SharedPreFerences 클래스의 객체를 할당한뒤(getSharedPreFerences를 참조해야함), SharedPreferences클래스에 정의된 Editor 를통해 putString()과 getString()을 통해 데이터를 저장&복원 하면 된다. 

각각의 저장과 복원의 메소드를 구현하여, 저장메소드는 onPause()메소드에 & 복원메소드는 onResume()메소드에 override 하면된다.


그렇다면 구체적으로 화면전환을 어떻게 하는지 공부해보자.

화면전환은 위에서 얘기햇듯이 두가지의 경우가 존재한다.

1. 메인레이아웃에 부분레이아웃을 표현하는 경우
2. 완전히 다른레이아웃으로 전환되는 경우

새로운액티비티를 생성하면 항상 XML 파일과 Java파일이 1:1로 생성된다. 그리고 XML의 화면구성을 해준다.

만약 부분적으로 가리는 형태를 구현하고자 한다면, XML상에 부모컨테이너 안에 Layout 팔레트에서 원하는뷰 객체를 할당하고,
뷰객체와 subLayout을 연결해주면 된다.

연결해준다는 것은 부분레이아웃을 뷰그룹 객체로 Inflation 한뒤에 메인레이아웃에 추가하는 과정을 얘기하는 것이다.

이때 시스템서비스에 정의된 LayoutInflater 클래스를 이용하여 inflate()메소드를 통해  subLayout을 Inflation 한다.

그러면 LayoutInflater 객체가 자동으로 inflation된 부분레이아웃을 메인레이아웃에 추가해준다.

이와달리 다른액티비티로 완전히 전환하고자 한다면, Intent 가 필요하다.


Intent
---
Intent는 android.content 패키지 안에 정의되어있으며, 앱구성요소간에 작업수행을 위한 정보를 전달하는 역할을 한다.

이게 무슨말이냐 를 알기쉽게 하기위해 process 개념이 필요하다.

하나의 Process위에 VM(virtual Machine) 하나가 올라가고, 그위에 App이 구성된다.

그렇다면 어떻게해야 나의 앱에서 다른앱을 띄울수 있을까?

이때 intent가 필요하다. Intent를 시스템으로 보내서 내가원하는 앱을 원하는방식으로 띄울수 있게된다.

Intent의 기본구성요소는 Action과 Data 이다.

Action은 수행할 기능이고, 데이터는 Action이 수행될 대상의 Data이다.

예를들자면, 어떤번호 A로 전화를 걸고싶어서 전화거는화면을 띄우고자 한다.

이때, Intent 객체의 생성자로 Action에는 ACTION_DIAL , data로 원하는번호 를 넣으면 되는것이다.

메인Activity에서 다른 액티비티를 띄우고자 한다면, 이때는 Intent 생성자파라미터로 메인액티비티와 다른액티비티를 넣은후
startActivity() 메소드를 호출하면 된다. 이때 이메소드의 파라미터로는 요청코드와 intent 객체이다.

부연설명하기 앞서 메인액티비티에서 다른액티비티를 띄우는 흐름부터 이해해야 한다.

1. 새로운 액티비티 생성
2. 새로운 액티비티의 xml 정의
3. 메인액티비티 에서 새로운 액티비티 띄우기 (=요청하기)
4. 새로운 액티비티에서 응답보내기
5. 메인 액티비티에서 응답 처리

후 다시 1로 돌아가는 형태이다.

startActivity()메소드를 통해 메인액티비티에서 요청코드와 함께 인텐트를 시스템에 보내면, 시스템은 인텐트에 구성되어있는 띄우고자하는 액티비티를 띄워준다.

만약, 다른액티비티를 띄운후 원래의 액티비티로 돌아가려 한다면 다른액티비티에 구현된 이벤트가 발생햇을때, SetResult() 를 호출한뒤 finish() 메소드를 호출하면된다.

SetResult() 메소드의 파라미터는 응답코드와 Intent객체 이다.

그러면 시스템은 응답코드와 함께 메인액티비티로 돌아가게 한다.

만약, 원래의 액티비티를 띄움과동시에 다른액티비티에서의 데이터를 전달받고자 한다면 어떻게 해야할까?

그렇다면 메인액티비티에서는startActivity메소드가 아닌 startActivityForResult 메소드를 호출하여 시스템에 intent객체를 보내고,
onActivtiyResult() 메소드를 override 하여 다른액티비티가 보낸 데이터를 전달받을수 있다.

이때, onActivityResult() 메소드의 파라미터는 요청코드,응답코드 와 intent객체 이다.
요청코드와 응답코드를 비교하여 어떤액티비티로 부터 온 응답인지를 구별하여 더복잡한 여러개의 액티비티로의 전환을 처리할수있다.

이외에도 Intent에는 다른여러가지 속성이 있다.

대표적인 것으로는

1. Category : Action이 수행되는데 필요한 추가적인 정보를 제공함
2. Type: Intent에 들어가는 데이터의 MIME타입을 명시적으로 지정함
3. Component: Intent에 사용될 컴포넌트 클래스 이름을 명시적으로 지정함 (파라미터는 패키지이름과 클래스이름)
4. Extra Data: Intent에 들어있는 Bundle 객체에 데이터를 넣어 추가적인 정보들을 전달할수있음

이중에서 Extra Data 부분을 좀더 유의깊게 보자면,

메인엑티비티에서 서브엑티비티에 데이터를 전달해야하는 경우에 Bundle 객체에 putExtra()메소드를 통해 데이터를 추가하고 getExtra()로 데이터를 가져올수 있다.

이때, 단순히 문자열이거나 정수타입이면 그대로 사용하면 되지만, 객체데이터를 전달할때는 문제가발생한다.

자바의 I/O는 모두 바이트타입만을 취급하기때문에 객체데이터를 전달하려면 바이트배열로 변환한후(직렬화한후)에 전달해야 한다.

바이트배열로 변환하기 위해서는 Serializable 과 Parcelable 인터페이스를 구현하는 방법으로 사용하면 된다.

그중에서 Parcelable 방식이 좀더 빠르고 크기가 작아 안드로이드에서 권장하는 방법이다.

Parcelable 의 중요한메소드는 3개가 있다.

1. describeContents() : 직렬화 하려는 객체의 유형을 구분할때 사용한다. 보통은 0를 return 한다
2. writeToParcel() : 데이터를 parcel객체로 만든다
3. CREATOR상수: parcel 객체로부터 데이터를 읽어들여 객체를 생성해줌


Task
---

위에서 설명햇듯이 하나의 Process위에 VM(virtual Machine) 하나가 올라가고, 그위에 App이 구성된다.

만약, 다른 액티비티를 띄운후에 돌아가기 키를눌러 원래의 액티비티로 돌아와야 하지만,  각각의 Process는 독립적이기 때문에 다른 Process에 정보공유는 어렵다.

이때 Task 로 어떤 화면들이 동작할지의 흐름을 관리할수있다.

Task는 시스템에 의해 자동적으로 관리되지만, 직접제어해야하는 경우도 발생한다.

이때는, manifest에서 제어할수 있다.

manifest의 activity 태그에 launchMode 속성을 추가하여 그값에따라 화면을 스택에넣어 관리시키게 할수있다.


모든 예제들의 코드는 [깃허브주소][깃허브주소](https://github.com/jowunnal/studyAndroid "github link") 에있다.
