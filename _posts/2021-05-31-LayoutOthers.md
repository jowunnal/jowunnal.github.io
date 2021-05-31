---
title: "[Android] Layout"
categories:
- Android
tags:
- Study
---

지난번 공부에서는 LinearLayout에 대해서 공부했었다. 이번포스팅에서는 그외의 다른 Layout들에 대해서 복습하겠다.


Layout에는 대표적으로 5개의 종류가있다.

---

1. ConstraintLayout
2. LinearLayout
3. RelativeLayout
4. TableLayout
5. FrameLayout

---

책에서 LinearLayout 다음으로는 RelativeLayout을 소개한다.

RelativeLayout은 위치를 다른 view 나 부모컨테이너에 대해 상대적으로 view의 위치를 결정시킨다.

부모컨테이너에 대한 상대적인 위치와 다른view 로의 상대적인 위치를 결정시키는 속성에는 서로 차이가있다.

부모컨테이너에 대한 상대적 위치를 결정시키는 속성은 Layout_align 뒤에 parent 나 center 에대해 위치를 결정시킨다.

예를들면 Layout_alignParentTop 을 하게되면 , 부모컨테이너의 상단부에 위치시키게된다.


다른view에 대한 상대적 위치를 결정시킬때는, Layout_ 이후 위치를 명시해준다.

예를들면, Layout_blow 속성값에 다른view의 id값을 명시해주면, 그 view의 아래쪽에 view를 위치시키게된다.

![RelativeLayout](/assets/RelativeLayout.JPG)

위의 예제는 버튼1,2,3 을 생성한뒤에, 버튼2를 width와 height를 각각 match_parent로 한다.

그리고 버튼2의 위치를 버튼1의 아래에, 버튼3의 위에 위치시키도록 한다.

상대적위치를 결정시키기 위해 부모컨테이너는 relativelayout으로 바꾸고, 다른 view에 의해 위치를 결정시키기 때문에 layout_blow와 layout_above 속성에 각각 버튼1과3의 id값을 속성값에 넣어준다.


다음은, TableLayout 이다.

TableLayout은 표나 엑셀시트처럼 격자형태로 구성하는 형태이다. 그렇기에 행과 열의 형태를 띈다.

TableLayout 안에는 TableRow라는 태그들이 들어가있는데, 이는 한 행을 의미한다.

그리고 각 행의 column은 TableRow 태그안에 들어가는 view 가 된다.

![TableLayout](/assets/TableLayout.JPG)

위의 예제에서는 LinearLayout 내에 TableLayout을 만들면, 그안에 TableRow들이 생긴다. 그중 두개만 남긴뒤, 각TableRow안에 버튼3개를 넣는다.

여기서 중요한 속성이 나오는데, 부모컨테이너에 대해 여유공간을 할당하여 각 row의 위치를 재지정시켜주거나, 
columns의 위치를 재지정 시켜주는 속성이 있다.

row의 위치를 재지정시켜주는 속성은 Stretch columns와 shrink columns 이다. 먼저,  Stretch columns 는 부모컨테이너의 폭에 맞게 TableRow태그들 안에 있는 view들의 폭을 강제로 확장시킨다.

이와반대로 shrink columns는 부모컨테이너의 폭에 맞게 TableRow 태그들 속의 view들의 폭을 강제로 축소시킨다.

이속성은 TableLayout 태그내에 명시하며, 값은 인덱스갯수를 준다.  예를들어, "0" 을 명시하게되면, 첫번째 인덱스에 해당하는 View가 나머지 여유공간을 모두 차지하여 가로방향을 꽉 채워준다. 

또는 "0,1" 을 명시하게되면, 첫번째와 두번째 인덱스에 해당하는 View가 나머지 여유공간을 모두 가져 가는 형태이다.

columns 의 위치를 재지정시켜주는 속성은 layout_columns 와 layout_span 이다.
각 row의 view들은 각각 자동으로 index번호를 순서대로 0,1,2 ... 에 해당하는 값을 지정받는데, layout_column 속성은 순서를 설정할수있다.
예를들어, layout_column에 2를주게되면,  3번째 위치에 view가 가게되며 그다음 view들의 위치에도 영향을 주게된다.

layout_span은 여러개의 column에 걸쳐서 몇개를 차지하게 할것인가를 결정하는 속성이다.
예를들어, layout_span에 2를 주게되면, 2개의 column만큼을 view가 차지하게 된다.


다음은, FrameLayout 이다.
FrameLayout은 스택과 같은 구조로 아래부터 위로 쌓아가는 형태로, visibility 속성이 있다.

visibility 속성은 쌓여있는 각 view들이 보일것인가(visible), 보이지않을것인가 (invisible) 또는 없애다 (gone) 이있다.

invisible와 gone의 차이점은, invisible은 존재하지만 보이지않는 속성이고 gone은 완전히 존재하지않아서 다음view가 그위치를 채우는 형태입니다. 

![FrameLayout](/assets/FrameLayout.JPG)

위의 예제에서는 button의 클릭에따라 imageView가 전환되는 예제입니다.
이를위해 FrameLayout내에 imageView 두개를 넣어 각 속성을 invisible와 visable로 구성하여 mainactivity.java에서 버튼의 onclick 메소드가
호출되엇을때, 두개의 imageview의 visibility 속성을 바꿔주게 됩니다.


마지막으로 ScrollView 입니다.

ScrollView는 추가된 뷰의 영역이 한눈에 보이지 않을때 스크롤을 사용하여 전체를 보기위한 view 입니다.

ScrollView는 default가 수직방향 이다. 만약 수평방향을 원한다면, HorizontalScrollView를 사용하면 된다.

![ScrollView](/assets/ScrollView.JPG)

위의 예제에서는 수평방향 HorizontalScrollView 내에 ScrollView를 구성하고, 그안에 imageView를 넣어 버튼의 onclick 메소드에 의해
imageview 의 사진이 바뀌거나,전환되는 예제이다. button1을 눌럿을때는 사진이 바뀌게되고, button2를 눌렀을때는 FrameLayout에 의해 사진이 전환되게 된다.

이예제는 xml이아닌 activity.java 에 명시하여 event에의해 사진이 전환되거나 바뀌게 만들었는데,
중요한부분은 res/drawable 에 추가된 그림을 가져오는 부분이다.

res/drawable 폴더에 접근하기 위해서는 getDrawable() 메소드를 이용한다. 그런데, getDrawable 메소드는 Resources 객체에 정의되어 있으며, Bitmap Drawable 객체에 의해 만들어지는 메소드다.

따라서, Resources res 라는 객체를 할당하여 res객체에 getResource() 메소드로 resource를 가져오고, res객체에 있는 getDrawable() 메소드로 res/drawable에 접근하여 bitmapdrawable 객체에 할당하면 원하는 그림파일을 가져올수있다.

그후 Bitmap.getIntrinsic width와 height 값을 가져와 할당시켜주면 끝이다.

모든 내용은  [깃허브주소](https://github.com/jowunnal/studyAndroid, "github link") 에 있다.
