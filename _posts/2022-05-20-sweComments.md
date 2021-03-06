---
title: "[Projects] 소프트웨어 공학의 소개"
categories:
- Projects
tags:
- Study
---

학교 커리큘럼에 포함된 3학년1학기 의 '소프트웨어 공학의소개' 에 대해 현재 프로젝트 계획~설계 까지 진행한 내용에 대해서 전체정리를 해볼까한다.

---
참고서적:  소프트웨어 공학의 소개 2판 -한혁수 지음
---

# 프로세스
이책의 첫 중요챕터의 키워드는 '프로세스' 이다. 프로젝트를 수행하는데 있어 어떤 개발 프로세스를 사용하고, 어떤 프로젝트 관리 프로세스를 적용할것인가 를 중요하게 서술한다.

실제 교수님의 강의내용중에서도 이번강의를 현재 80프로 정도 진행한 시점에서 봤을때, 나의 '아이모 잡학사전 with 알람' 앱이 얼마나 주먹구구식으로 만들어지고 효율이 극바닥이었는지를 깨닳게 해주는 포인트가 많았다.

### 개발 프로세스
먼저, 개발생명주기에 대해서 배우는데 개발생명주기에는 내가 여태 적용해서 만들어왔던 '주먹구구식 모델', 그리고 주먹구구식 모델의 단점인 문서화가 없어 개발 관리의 어려움과 진행사항을 명확히 할수 없다는 단점을 보완하여 만들어진 '폭포수 모델', 

폭포수 모델의 단점 중 개발초기에 요구사항을 명확히 하기 어렵다는 단점을 보완하여 만들어진 '원형 모델' , 폭포수모델의 장점과 원형모델의 장점을 합치고 위험을 분석하고 관리하는 모델인 '나선형 모델', 

폭포수모델의 문제점인 각단계가 완료되기 전까지 대기상태가 되고 개발후반부가 되어서야 결과물의 제품이 고객의 요구사항이 반영된것인지 알수있다는 문제점을 보완하기 위해 만들어진 통합프로세스 모델(UP모델),

마지막으로 많은 기업에서 사용하며 너무 많은 문서화보다 최소화하여 개발에 집중하고 팀원과 고객과 협업 및 의사소통을 중시하는 애자일 모델중 XP모델 에 대해서 설명하고 있다.

이중에 현재 강의 프로젝트 진행에는 원형모델을 적용했지만, 사실 수업의 진행이 끝나고 진행된 챕터에대해서 프로젝트를 진행하는 방식으로 진행했기 때문에 초기에 맞춰진 일정에 따라 진행할수가 없었고, 애초에 이강의의 목적은 '이러한것을 사용해서 개발을 해야한다.' 가 목적이기때문에 약 2개월반 정도의 시간내에 학습하면서 적용하기에 무리가 있었던건지 교수님 역시 개발생명주기와 계획서내에 일정을 만들어 오셧지만 지키는 여부에 대해서는 중점을 두시지 않았다.

하지만, 현재 다른 기업실무자의 강의 무신사UX/UI디자인, 대한통운 빅데이터, 크래프톤 에서 강조했던 포인트들중 하나가 WBS 였다.

그만큼 어떤 개발프로세스를 가지고 WBS를 만들어 그내용대로 프로젝트가 진행되고 관리되는지의 역량이 매우 중요한것 같다. 즉, 이후의 프로젝트를 진행할때는 WBS를 적용하여 그내용에 대해서 반드시 정리해야 한다고 생각했다.

팀장인 입장에서 사실 이부분이 완벽하게 지켜내 졋다고는 말할수 없었다. 이부분은 위험관리 탭에서 서술해보겠다.

### 프로젝트 관리 프로세스
프로젝트 관리 프로세스에는 프로젝트를 계획하고 종료될때까지 , 실행하고 통제하여 계획한 내용대로 프로젝트가 진행될수 있도록 관리하는 프로세스를 담고있다.

책의 내용에서는 관리 지침서 두가지를 서술하고있는데, 첫번째는 PMBOK의 프로젝트 관리 지침서 이고 두번째는 CMMI 이다.

PMBOK의 관리지침서는 프로젝트를 진행하는데 있어서 도움이 되었다고 검증된 방안들을 모아놓은 지침서 이고, CMMI는 조직의 성숙도에 따라 관리 프로세스를 점진적 개선을 유도하는 지침서 이다.

이두가지의 지침서의 목적은 소프트웨어 개발의 어려움들로 인해 프로젝트의 실패율이 높아지고, 이를 최소화 하기위해 사용하는 것이다.

---
# WBS
프로젝트 계획및 통제 챕터부분에 서술되있는 'WBS' (Work Breakdown Structure)은 위에서 서술한 바와같이 기업들에서도 중요시하게 생각하는 스케쥴링 방법이다.

프로젝트를 톱다운방식 으로 세분화하여 단위작업에 대해 파악하는 기법인데, 아래로갈수록 상세화 되고, 최하위 작업을 작업패키지(Work Package) 라고한다.

작업패키지는 작업의 원가와 일정을 신뢰할수있는 정도로 산정가능한 최소 단위 라고하는데,  작업패키지는 각단계의 산출물이 된다. (계획서,요구사항명세서,설계서,테스트보고서 등등)

프로젝트는 최소한의 비용으로 계획된 일정내에 가장좋은 품질의 소프트웨어를 만드는것이 목적이므로, 이는 분명 프로젝트 진행에 있어서 비용을 산정하고, 일정을 계획할때 작업패키지를 가지고 진행해야 함을 의미한다고 본다.

즉, 어느 작업에서 어떤 산출물이나와야 하는지 정의해놓는 것이다.

그외에 프로젝트 비용산정중 경험중심인 델파이, 크기중심의 LOC/COCOMO, 기능중심의 FP 를 이용하여 비용을 산정하는 부분은 사실 크게 중요하다고 체감되지 않았다.

이는분명 정보처리기사 와 여타 강의시험내에 공식을외우고 시험을치고 답이 명확하게 나온다는 측면에서 문제내기 좋은부분이지, 사실 기업에서 이부분을 관리하는건 재무팀이 아닐까? 생각이든다.


![wbs](/assets/wbs.PNG)

---

# 요구사항 명세서
요구사항 챕터에서는 고객의 요구사항을 추출한뒤 명확하게 분석하고 그내용을 체계적으로 명세하고 검증하여 확실하게 고객의 요구사항을 반영하여 소프트웨어를 개발하는것이 주 목적이다.

즉, 고객이 요구한 내용을 명확하게 이해하고 소프트웨어를 개발하여야 개발된 제품을 고객이 만족할수 있다는 것이다. 당연하게도 고객이 요구한 내용이 아니였다면.... 생각하기도싫다.

요구사항 개발 프로세스에는 요구사항추출,분석,명세,검증 단계를 따른다.

#### 요구사항 추출
요구사항 추출단계에서는 인터뷰와 시나리오기법을 통해 고객의 추상적인 초기 요구사항을 정확하고 명확하게 파악하는것이 목적이다. 인터뷰를 통해 개발된 제품이 사용될 조직내의 정보와 사용자들의 정보를 추출하고, 시나리오기법을 통해 사용자들과 시스템간의 상호작용을 시나리오로 작성하여 시스템요구사항을 추출한다.

시스템요구사항 이라 함은, 고객이 시스템의 어떤 기능을 이용하는데 있어서 선행해야하는 조건 예를들어,사용자정보를 입력하기위해서 메인화면에 접근하여야한다는 사전조건과

기능을 수행하는 흐름들중 기본흐름(실제 수행되는 기본적인 흐름),대안흐름(기본흐름 내에서 선택적인 다른 흐름이 수행될때),예외흐름(기본흐름을 수행중에 발생되는 에러같은것들) 그리고 모든 흐름을 수행하고 나서 시스템의 상태인 사후조건 을 포함하는 내용이다.

#### 요구사항 분석
요구사항 분석단계의 주목적은 추출된 요구사항의 내용을 완전하고 일관성있는 요구사항으로 정리하는 것이다.

구조적분석과 객체지향 분석을 통해 사용자와 시스템간의 관계를 정의하여, 시스템의 내용을 계층적이고 구조적으로 표현하여야 한다.

구조적분석은, 시스템 기능을 중심으로 데이터의 흐름 및 프로세스들을 정의하는 분석기법이다.

강의에서는 교수님은 객체지향분석을 중점적으로 강의하셧는데, 객체지향 분석은 만들어진 시나리오를 가지고 유스케이스 모델을 구축하는 기법이다.

그외 명세와 검증은 생략하겠다.

---

# 유스케이스 모델
유스케이스 모델에는 유스케이스 다이어그램, 클래스 다이어그램, 시퀀스 다이어그램 순으로 작성하였다.
### 유스케이스 다이어그램
유스케이스 다이어그램의 구성은 3가지이다.

1. 액터 : 액터라함은 시스템내에서 기능을 수행하는 주체들 즉, 사용자와 외부시스템 이 된다.
2. 유스케이스: 실제로 수행되는 기능들을 간략하게 표시한 것을이다. 즉, 로그인기능 이나 사용자정보 입력기능,수정기능,삭제기능,조회기능 과같이 표현한다.
3. 관계 : 액터와 액터사이의 관계, 액터와 유스케이스 간의 관계, 유스케이스와 유스케이스 간의 관계를 정의한다. 

제일먼저 액터와 유스케이스를 추출하고, 식별하는 과정을 거친다. 이중에 명사추출법이나 동사추출법을 이용하여 액터와 유스케이스를 추출하는데 자세한 내용은 책을 참조하길바란다.

사용자가 어떠한 기능을 수행하는가를 생각하면 액터와 유스케이스를 나누는것은 어렵지않다고 생각한다. 즉, 위의 과정을통해 고객의 요구사항을 명확히 이해하고 시스템과 사용자관의 흐름과 그관계가 어떠한지 분석해보면 유스케이스 다이어그램을 작성하는것은 어렵지않다.

관계에는 4가지 종류가 있다.

1. 연관관계: 액터와 유스케이스 간의 연관성을 표현하는 관계이다.
2. 포함관계: 어떤 유스케이스를 수행하는데 있어서 반드시 선행되서 수행되어야할 유스케이스를 표현한다. A를수행하는데 B가 선행되어야한다면, A <----- B 와같이 표현한다.
3. 확장관계: 어떤 유스케이스를 수행하는데 있어서 선택적으로 수행할수도있고,안할수도 있는 유스케이스를 표현한다. A를 수행하는데 선택적으로 B가수행된다면, A----->B와 같이표현한다.
4. 일반화관계: 액터나 유스케이스에서 구체화되는 액터나 유스케이스를 표현하는 방법이다. 이는 상속의 개념과 유사하다.

이러한 4가지 관계를 시스템 바운더리 내에 액터와 유스케이스들 간에 표현하여 누가 어떤기능을수행하고, 어떤기능이 수행되는데있어서 선행되거나 선택적으로 수행되는가를 표현할수있고 이를바탕으로 기능 시나리오를 작성할수 있다.

![usecase_diagram](/assets/usecase_diagram.PNG) 

### 클래스 다이어그램
설계의 내용에 포함되는 것으로, 클래스 다이어그램은 실제 구현되는 모든 클래스와 그 클래스간의 관계를 표현하여, 이를통해 설계된 내용을 바탕으로 코딩만하면 구현이 되어야 한다.

클래스 다이어그램의 구성은 2가지 이다.

1. 클래스 : 실제 구현될 모든 클래스를 객체지향방법으로 표현한다.
2. 관계 : 클래스와 클래스간의 관계를 표현한다.

사실 이개념을 알기위해 객체지향의 개념인 캡슐화,상속,다형성,추상화 의 개념을 필수적으로 이해해야 한다. 이부분은 여타 잘정리된 게시글을 참조하길 바란다.

클래스들은 3가지로 분류하는데, 이는 MVC 디자인패턴과 유사하다.

1. 바운더리클래스(Boundary) : 실제 화면을 구성하는 클래스로, 화면내에 존재하는 뷰들과 그뷰들의 이벤트핸들러가 각각 속성과 오퍼레이션에 표현된다.
2. 컨트롤클래스(Control): 화면의 이벤트핸들러에 의해 수행되는 기능들이 담기는 클래스로, 반드시 데이터를 관리하는 Entity클래스에 접근하려면 boundary에서 control을 거쳐야 한다.
3. 엔터티클래스(Entity): 데이터를 관리하는 클래스로, 속성과 오퍼레이션에 각각 실제 데이터들과 getter 와 setter가 표현된다.

MVC 디자인 패턴과 유사한데, 먼저 액터는 바운더리 클래스를 호출할수 있으며, 그외의 다른클래스는 호출할수 없다. 바운더리 클래스는 다른 바운더리클래스나 컨트롤 클래스를 호출할수 있지만 엔터티클래스는 호출할수 없다.

컨트롤클래스는 바운더리클래스,다른 컨트롤클래스, 엔터티클래스를 각각 호출할수 있지만 액터를 호출할수없다. 마지막으로 엔터티클래스는 컨트롤클래스에게 호출받을수만 있으며 다른클래스를 호출하거나, 그외 다른클래스에게 호출받을수 없다.

그렇다면 이러한 아키텍쳐를 추상화하는건 왜하는것인가?  근본적인 목적은 뷰와 데이터를 분리하여 그들사이의 종속성을 줄이고 단위작업,모듈화를 하여 재사용성을 늘리는것이다.

즉, 실질적으로 뷰는 화면을보여주는 껍데기에 불과하며 모든 기능은 컨트롤이 담당하고 데이터는 엔터티에서 관리하여,  뷰와 데이터를 분리하여 설계하는 것이다. 

이러한 목적은 MVVM에서도 동일하게 적용된다. 화면을담당하는 View와 데이터를담당하는 Model 그리고 그사이의 기능을담당하는 ViewModel

이들은 모두 동일한목적인 종속성을 줄이기 위해, 단위테스트를 하기위해, 재사용을하기위해 의 이점을 수행하려고 이루어진다.

특히나, DataBinding 과 observer pattern, livedata 의 활용으로 뷰와 뷰모델사이의 의존성을 줄이고, 뷰의변경에 즉시 뷰모델에게 알려주어 변경사항을 적용함으로써 boiler plate를 줄인다.

![usecase_up](/assets/class_up.PNG)

![usecase_down](/assets/class_down.PNG)

가장먼저 사용자가 정보를 입력하는 화면이 만들어지고, 사용자가 만약 정보를 입력한적이 있다면 메인화면이 바로 열리게된다.

메인화면에서는 사용자정보를 BMI지수를통해 보여주고, 식단정보를 해당식단명과 아침인지,점심인지,저녁인지를 구분해주는 식단구분자와 전체식단의 영양소,칼로리를 계산하여 비율로 나타내어주며 오늘섭취할 물의목표량과 섭취한 물의양을 나타낸다.

또한 달력화면은 RecyclerView로 만들어 일주일치를 메인화면에 보여주고 ->화살표 버튼을 클릭하여 한달치 달력을 보여주는 화면으로 전환 할수있다. 그외 식단과 사용자정보,물정보는 각각의 뷰를 클릭함으로써 전환가능하다.

이를통해 클래스다이어그램에서는 메인화면에서는 각각의 뷰에 전환가능하기 때문에 내부적인 코드에서 메인화면에서는 각각의 화면의 객체를 가진다고 정의했으며, 관계다중성은 1:1이된다.

각각의 화면에는 화면내의 RecyclerView의 내부 아이템뷰들을 표현하기위해 RecyclerViewAdapter 화면클래스의 객체를 가지며, 기능을수행하는 필요한 각각의 viewmodel클래스객체를 가진다. 이들 역시 모두 1:1이 된다.

RecyclerView는 클릭리스너가 구현되어있지 않기때문에, 클릭리스너 인터페이스 클래스를 생성하고, RecyclerView가 있는 화면클래스에서 리스너객체를 object로 생성하여 adapter로 넘겨주면 adapter클래스내에서 넘겨받은 리스너객체를 인식하고 override를 통해 구현하여 내부 viewholder에서 클릭된 아이템의 위치값에 따라 클릭된아이템뷰에 해당하는 정보를 처리하도록 구성하였다.

데이터는 Room 라이브러리를 이용하여 뷰모델이 데이터베이스 객체를 가지고 Dao인터페이스에 정의된 각각의 기능의목적에따른 query문을 수행함으로써 데이터의 SIUD를 수행한다.


### 시퀀스 다이어그램
설계된 클래스다이어그램의 기능들을 시퀀스다이어그램으로 표현한다.

사용자가 화면상에서 어떠한 뷰를 클릭하여 이벤트핸들러가 발생하고, 그에따라 컨트롤클래스의 객체를 사용하여 그안의 기능메소드를 사용하고, 그에따라 어떤 엔터티클래스를 참조 혹은 사용하는가를 시퀀스다이어그램에서 시나리오를 바탕으로 흐름을 표현한다.

![sequance](/assets/sequance.PNG)

사용자가 식단을 구분하고(아침,점심,저녁) 식단화면의 해당식단의 영양성분조회 버튼을 클릭하면, 영양성분조회 화면이 생성됨과 동시에 그화면내의 RecyclerView를 표현하는 adapter클래스 객체가 생성된다.

viewmodel 클래스에서 식단화면에서 가져온 해당식품이름을 Retrofit 라이브러리를 이용하여 외부공공영양정보시스템에 영양성분조회를 요청하면, 해당식품이름이 포함된 여러개의 식단들의 영양성분들을 응답한다.

이를 Viewmodel 클래스에서 받아 영양성분조회 화면에 보여주고, 사용자가 원하는 식단을 클릭하면 이내용을 viewmodel에 저장하여 식단화면내에 해당식단이름과 영양성분을 piechart로 보여준다.

---


위의 유스케이스 모델을 바탕으로 코딩만하면 구현이 완료될 예정이다.

이수업은 사실상 소프트웨어쪽으로 진로방향을 정한 이들에게 필수적인 교과목이다. 이를 경험하지 못한채로는 실무에서 힘들수밖에 없다.

이후 구현이 완료되면 개발에 대한 리스크관리와 더불어 전체 코멘트를 남겨야겠다.
