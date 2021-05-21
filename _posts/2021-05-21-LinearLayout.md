---
title: LinearLayout
categories:
- Android
tags:
- Study
---

---

참고서적: Doit 안드로이드 앱 프로그래밍

---

Linearlayout 에 대해 알기전에, 먼저 layout의 종류들에 대해서 알아보자.

Layout에는 크게 5개의 종류가있다.

1. ConstraintLayout (제약조건기반 layout)
2. LinearLayout (박스기반 layout)
3. RelativeLayout ( 규칙기반 layout)
4. FrameLayout (싱글기반 layout)
5. TableLayout (격자기반 layout)

이 5가지 layout 중에서 가장먼저 책에서는 LinearLayout을 소개하고있다.
나머지 layout 들은 공부가 되는대로 복습포스팅을 하겠다.

Linear Layout 이란 말 그대로 선형으로 만들어지는 layout으로, Linear Layout의 필수속성 세가지는 width,height, orientation 이다. (가로,세로,선형방향)
orientation 의 속성은 vertical 이거나 horizontal 둘중 하나를 가진다.
vertical 일경우 세로로 view들을 가지며, horizontal 일경우 가로로 view들을 가진다.

이것을 응용해서 격자형태를 만들수있는데, vertical 의 Linear Layout 안에 horizontal 속성의 Linear Layout을 넣게되면 다음 그림과 같은 격자형태를 만들수있다.

![linearLayout1](/assets/LinearLayout1.JPG)

그걸 한층더 응용하면, 위의 상태에서 다시 vertical 속성을가지는 LinearLayout을 넣으면 다음 그림과 같은 형태를 가질수있다.

![linearLayout2](/assets/LinearLayout2.JPG)

이런식으로 orientation 의 속성을 어떻게 구성하는가, 그리고 LinearLayout의 중첩들에대한 orientation 의 각각의 속성들을 어떻게 구성하는가 에 따라 매우 unique 하고 복잡한 형태를 표현할수 있다.

Linear Layout의 다른속성중에는 (이책에서 다룬 속성) gravity(정렬), margin&padding, weight 속성이다.

첫번째 gravity 속성은 정렬을 해주는 속성인데, 이것도 view에대한 정렬 과 view의 content에 대한 정렬 두가지로 나뉘게된다.
view 들을 구성할때 LinearLayout 에서 vertical 로 구성하게되면, 각 view들의 width를 wrap_content로 했을때, 남는 공간들이 발생하게 된다.

![linearLayout3](/assets/LinearLayout3.JPG)

이때, 더불어서 설명해야하는 공간개념이있다.
view의 위치를 결정시키는데 있어서 view가 갖는 공간은 cell에 포함되며,
content의 위치를 결정시키는데 있어서 content가 갖는공간은 view에 포함된다.
view의 위치는margin 속성들에 의해 결정되고, content의 위치는 padding 속성들에 의해 결정된다. margin과 padding은 각각 top,bottom,right,left 가 존재하며 그냥이름만(margin or padding) 쓰는경우에는 4가지 모두를 한번에 제어한다.
이것을 그림으로 표현하면 다음과같다.

![linearLayout4](/assets/LinearLayout4.JPG)

이 남는 공간들이 생기면 , 일반적으로 view들을 정렬(gravity)를 하게된다.
이때 사용하는 속성은 layout_gravity 이고, 이것을 사용하여 left,center,right 와같이 
좌,중간,우 등등으로 정렬시킬수있다.(단, 남는공간들은 남아있게된다. 아마도 보기좋게하는듯 하다)

![linearLayout6](/assets/LinearLayout6.JPG)

content에 대한 정렬의 속성은 gravity 이다. 
content의 구성은 text 이거나 그림 일수있는데, content의 위치배치를 그림으로 보면 다음과같다.


![linearLayout7](/assets/LinearLayout7.JPG)

이그림은 vertical 속성의 LinearLayout 안에 button 3개를 만들었다.
button 1과2는 left, center로 하고 width는 match_parent로 했다.
button 3은 width와 height 모두 match_parent로 구성해서 나머지공간들을 모두 차지하게끔 했고, text값을 그 view의 중간에 위치시키기 위해서 '|' 연산자를 통해 center_horizontal|center_vertical 로 했다. 
위와같이 gravity 속성은 '|' 연산자를통해 여러개의 값을 같이 설정시킬수있다.

위의 gravity는 남는공간 들이 나오면 일반적으로 정렬시키는데 있어서 사용햇다면,
남는공간에 새로운 view를 추가하여 그 크기를 조절해, 남은공간들을 채우거나 정렬속성을 이용하여 위치를 지정시킬수도 있다.

이를 위한 개념이 margin 과 padding  개념이다.

![linearLayout5](/assets/LinearLayout5.JPG)

view의 테두리 (border)는 아주미세하게 view와 view 사이를 띄워놓고있다.
view의 바깥은 margin 속성을 통해 띄워놓으며, view내부의 content는 padding 속성을통해
테두리와 content 사이를 띄워놓고있다.

![linearLayout8](/assets/LinearLayout8.JPG)

위의그림을보면 살짝씩 띄워져있는 모습을 볼수있다.

이를통해 정렬하는 예제를 수행해보았다.

![linearLayout9](/assets/LinearLayout9.JPG)

부모컨테이너인 LinearLayout 내부에 3개의 textview(1,2,3) 을 만들었다.
각 textview에 text값은 textview 로 했고, 그위치들을 자세히 보고 알기위해서 
textcolor (글자색)과 background(배경색) 을 각각다르게 지정했다.
그리고 textview(1,3)는 padding 속성을통해 content의 위치를  layout_margin 속성을 통해서 각각의 textview들의 top,bottom,right,left 로부터 떨어진모습을 확인할수있었다.
textview (2)는 layout_margin 속성을통해 textview(1,3)으로부터 떨어진 모습을 확인할수있었다. 이 두가지 속성을통해 남은공간을 어떻게 처리할것인가는 상황에따라서 unique 하게 할수잇을거같다.

마지막으로 weight 속성은 남는공간들에 대해서 비율을 주어서 재배치 시키는 속성이다.
vertical 방향을 가지는 LinearLayout(1)안에 horizontal 방향을 가지는 LinearLayout(2)을 두었다고 가정해보자.
이때, (2) layout에 두개의 textview를 두었을때(width 는 wrap_content), 남는공간들이 역시 발생하게된다. 이때 weight 속성을 통해 남는공간들을 두개의 textview 에 비율을 할당해서 재배치할수있다.

![linearLayout10](/assets/LinearLayout10.JPG)

첫번째 vertical 의 LinearLayout 은 1:3 비율로 재배치했다.
각각의 weight 속성에 1과 3을 주면된다.
그리고 두번째 와 세번째는 공통적으로 1:2 비율을 주었든데 그림을보면 다른것을 볼수있다.
이 이유는 마지막 textview 에 대해서 width 값을 0dp로 주었기 때문이다.
textview의 width를 0으로 주게되면 , 부모 컨테이너인 vertical 의 LinearLayout의 가로공간이 0이 되고 (아무것도없는상태), 그공간을 1:2 비율로 재배치한것이고,

그에비해 두번째 textview는 두개의 textview를 각각 wrap_content로 배치시킨뒤에 남은공간을 각각 1:2 비율로 더주어 배치시켯기 때문에 다르다.

위의 모든예제들에 대한 코드는 [깃허브주소](https://github.com/jowunnal/studyAndroid,"go github") 에있다.
