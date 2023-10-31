---
title: "[Android] Retrofit2 로 Api통신하기"
categories:
- Projects
tags:
- Study

toc: true
toc_sticky: true
toc_label: "목차"
---

[공공데이터 포털](https://www.data.go.kr "공공데이터포털") 에서 울산광역시 음식점 현황의 xml파일셋을 api로 요청하는 예제를 작성해보았다.

# 준비
---
Retrofit2는 서드파티 라이브러리로 직접 dependencies에 추가하여야 한다.

```kotlin
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation "com.squareup.okhttp3:logging-interceptor:4.9.3"

    implementation 'com.tickaroo.tikxml:annotation:0.8.13'
    implementation 'com.tickaroo.tikxml:core:0.8.13'
    implementation 'com.tickaroo.tikxml:retrofit-converter:0.8.13'

    kapt 'com.tickaroo.tikxml:processor:0.8.13'
```
		
Retrofit 과 인터셉트를 통해 통신과정을 로그로 찍어줄 okhttp라이브러리, 그리고 xml파일을 convert해줄 tikxml 라이브러리를 의존성에 추가하여야 한다.

그런다음, 데이터셋의 예시부분을 가지고 xml to POJO or DTO 로 object 클래스로 만들어야 한다. (json 이라면 안드로이드 스튜디오 플러그인에 json to kotlin을 이용하면 쉽게가능)

```kotlin
@Xml(name="rfcOpenApi")
data class RfcOpenApi(
    @Element(name="body")
    val body: Body,
    @Element(name="header")
    val header: Header
)

@Xml(name="header")
data class Header(
    @PropertyElement(name="resultCode")
    val resultCode: Int,
    @PropertyElement(name="resultMsg")
    val resultMsg: String
    )

@Xml(name="body")
data class Body(
    @Element(name="data")
    val data: Data,
    @PropertyElement(name="numOfRows")
    val numOfRows: Int,
    @PropertyElement(name="pageIndex")
    val pageIndex: Int,
    @PropertyElement(name="pageNo")
    val pageNo: Int,
    @PropertyElement(name="totalCount")
    val totalCount: Int
)

@Xml(name="data")
data class Data(
    @Element(name="list")
    val list: kotlin.collections.List<List>
)

@Xml(name="list")
data class List(
    @PropertyElement(name="address")
    val address: String?,
    @PropertyElement(name="city")
    val city: String?,
    @PropertyElement(name="company")
    val company: String?,
    @PropertyElement(name="foodType")
    val foodType: String?,
    @PropertyElement(name="lat")
    val lat: Double?,
    @PropertyElement(name="lng")
    val lng: Double?,
    @PropertyElement(name="mainMenu")
    val mainMenu: String?,
    @PropertyElement(name="phoneNumber")
    val phoneNumber: String?
){
    constructor() : this(null,null,null,null,null,null,null,null)
}
```

내용이 좀길다.. 먼저, 공공데이터 포털에서 제공하는 api의 데이터셋 예시부분을 가지고 xml태그 를 object 클래스로 변환하려면, 각상위태그를 상위클래스로 생성하고 하위태그를
상위태그의 필드로 생성한다. ( 필자의경우 [beautify xml to json](https://codebeautify.org/xmltojson "beautifyJSON") 을이용하여 json으로 변환한뒤 json to kotlin 플러그인으로 클래스를 생성했다. )

이후 자식element를 갖는 경우 @Element 어노테이션을, 더이상 자식 element 를 갖지않는 프로퍼티의 경우 @PropertyElement 어노테이션을 클래스와 변수마다 붙여준다.(자세한 설명은 [tickXML공식](https://github.com/Tickaroo/tikxml/blob/master/docs/AnnotatingModelClasses.md "link") 에서 참고하길 바랍니다.)

또한, POJO의 경우 아무것도 매개변수로 갖지않는 생성자가 필요하므로 위와같이 constructor():this() 로 생성한다.

POJO 작성이 완성되었다면, retrofit 클래스를 만들 차례이다. retrofit 클래스의 구성요소는 baseURL, client, converterFactory 이다.

- baseURL의 경우 공공데이터 포털에서 제공하는 엔드포인트를 제외한 베이스주소를 넣어주면 된다.
- client는 okhttpclient 객체를 빌드하여 넣어준다.
- converter는 json이라면 GsonConverterFactory를 xml이라면 TikXmlConverterFactory 의 객체를 생성하여 넣어준다.

```kotlin
private val baseURL="http://apis.data.go.kr/6310000/ulsanrestaurant/" // 베이스주소

    private val okHttpClient by lazy {
        OkHttpClient.Builder().addInterceptor(HttpLoggingInterceptor().apply {
            level=HttpLoggingInterceptor.Level.BODY
        }).build()
    }

    private val retrofit by lazy { // retrofit객체에는 베이스주소,client,converter를 등록해서 build()
        Retrofit.Builder()
            .addConverterFactory(TikXmlConverterFactory.create(TikXml.Builder().exceptionOnUnreadXml(false).build()))
            .baseUrl(baseURL)
            .client(okHttpClient)
            .build()
    }

    val iRetrofit by lazy { // iretrofit객체를 통해 만들어진 @GET문장으로 데이터 요청후 반환받음
        retrofit.create(IRetrofit::class.java)
    }
```

또한 만들어진 retrofit의 엔드포인트와 실질적인 데이터요청 쿼리를 작성할 IRetrofit 인터페이스를 작성하고 인터페이스 자바코드파일을 retrofit.create()의 매개변수로 넣어준뒤 iretrofit객체의 메소드로 실질적인 데이터요청을 수행하면 된다.

```kotlin
interface IRetrofit {
    @GET("getulsanrestaurantList")
    suspend fun getData(@Query("serviceKey", encoded = true) key:String ,@Query("city") city:String) : Response<RfcOpenApi>
}
```

*만약, api를 요청했는데 올바른 데이터가 응답받지 못하면서 okhttp를통해 인터셉트된 로그내역에 나오는 api요청주소를 들어갔을때, 서비스키가 잘못되어있거나 코드상에는 문제가없는데 런타임상에서 코드내용이 변경된다면 encoded=true를 반드시 넣어주어야 한다. 공공데이터포털에서 제공하는 서비스키는 보통 인코드된 키인데 인코드과정을 한번더 거치면서 서비스키의 내용이 변경되었기 때문에 반드시 encoded= true를 넣어준다.*

# 데이터 요청하기
---

현재 예제를 작성하면서 MVVM구조를 따르기 위해 노력했다. databinding 역시 앞의 프로젝트에는 없던것들을 추가하였고 boiler plate가 많이 줄었다.

로컬데이터베이스와 네트워크통신을 repository에 추상화하여 작성하고, repository 역시 싱글톤으로 작성하였다.

```kotlin
class LoginRepository(context:Context) { // repository에 네트워크통신(api)과 내장데이터베이스통신 을 추상화함
    //로그인 데이터베이스
    private val loginDao=LoginDatabase.getInstance(context).loginDao
    suspend fun getUser() = loginDao.getUser()
    suspend fun addUser(user: User)=loginDao.addUser(user)
    suspend fun deleteUser(user: User)=loginDao.deleteUser(user)

    //api 호출
    suspend fun getRestaurantData(key:String,city:String)= RestaturantRetrofit.iRetrofit.getData(key,city)

    //repository 의 싱글톤 인스턴스
    companion object{
        private var instance : LoginRepository ?= null

        fun getInstance(context: Context):LoginRepository{
            instance?: synchronized(LoginRepository::class.java){
                val rInstance = LoginRepository(context)
                instance=rInstance
                rInstance
            }
            return instance!!
        }
    }
}
```

각 viewmodel 에서 본인들이 필요한 메소드만 repository에서 사용하게 된다. apiViewModel을 살펴보자면,

```kotlin
class ApiViewModel(private val app: Application) : AndroidViewModel(app) {
    private val repository=LoginRepository.getInstance(app.applicationContext)
    private var mutablelist = MutableLiveData<ArrayList<List>>()
    val restaurantList get() = mutablelist

    fun getRestaurantData(city:String){
        var list=ArrayList<List>()
        viewModelScope.launch(Dispatchers.Main) {
            val response = withContext(Dispatchers.IO) { repository.getRestaurantData(app.getString(R.string.key)
                ,city) }
            if(response.isSuccessful){
                val result=response.body()?.body?.data?.list
                result.let{
                    if(it.isNullOrEmpty())
                        Toast.makeText(app.applicationContext,"검색된 식당이 없습니다.",Toast.LENGTH_SHORT).show()
                    else{
                        mutablelist.value= it as ArrayList<List>?
                    }

                }

            }
            else{
                Log.d("test","통신오류발생: "+response.errorBody())
            }
        }
    }
}
```

repository와 database객체를 생성하기위해 applicationContext가 필요하므로, AndroidViewModel을 상속받는 viewmodel 클래스를 정의했다.

내부에서는 viewModelScope상에서 동작하는 api통신 function이 있고, 응답받은값을 mutableLiveData의 value로 할당하고 그값을 Fragment 에서 observe 한다.

따라서, 값의 변경을 View에서 감지하여 화면의 내용을 자동으로 갱신하도록 하였다.(현재는 텍스트뷰에 단순히 리스트를 toString()으로 뿌려주고있지만, 향후 네이버지도Api를 이용하여 데이터셋에 포함된 경도,위도를 네이버지도에 매핑시켜줄 예정)

```kotlin
<Button
            android:id="@+id/button5"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_marginStart="8dp"
            android:layout_marginTop="16dp"
            android:layout_marginEnd="8dp"
            android:text="요청하기"
            android:onClick="@{()->apiViewModel.getRestaurantData(editApi.getText().toString())}"
            app:layout_constraintEnd_toEndOf="parent"
            app:layout_constraintHorizontal_bias="1.0"
            app:layout_constraintStart_toStartOf="parent"
            app:layout_constraintTop_toBottomOf="@+id/tv_api" />
```

또한, databinding을 통해 xml상에서 뷰의 위젯들의 listener이벤트를 xml코드내에 정의하였다.

```kotlin
 override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        KakaoSdk.init(requireActivity(), "")

        binding.lifecycleOwner=this
        binding.loginViewModel= loginViewModel
        loginViewModel.logFlag.observe(viewLifecycleOwner, Observer {
            if(it){
                Navigation.findNavController(view).navigate(R.id.action_log_to_home)
                loginViewModel.mutableLogFlag.value=false
            }
        })

    }
```

뷰의 코드도 간략해진 상태이다.

# 끝으로
---
retrofit2 와 okhttp라이브러리를 이용하여 공공데이터포털에서 주는 api를 요청하고 응답받는 예제를 작성해보았다.

databinding도 사용해보고 repository로 추상화하는등 계층화작업에 신경을 많이썻다.

추가적으로 네이버지도 api를 이용해서 받아온데이터의 위도,경도를 가지고 지도상에 매핑시켜주는 작업도 해볼 예정이다.

앞서 진행했던 json예제(식품영양성분) 와 달리 xml의 경우 simpleXmlParser의 deprecate로 인해 tikXml라이브러리의 경우 convert해줄때 adapter가 필요하다는 에러메세지가 계속 떳었다.
이유는 gson컨버터와 달리 최상위클래스가 태그상의 최상위태그 가 아니였던것 때문이었는데, 다른 블로그들의 포스팅과 tikXml 정식가이드에서는 typeAdapter가 필요하다는 말이 잇었다. (XML의경우 필요하다는것 같음)

애초에 json을 많이쓰고 xml은 예제들도 별로없엇기때문에 다음번에 한다면 무조건 json을 찾아서 해야겠다. xml은 너무 이상한 에러코드가 많이떳다.

# References
---
https://velog.io/@siennachang/Retrofit%EC%9C%BC%EB%A1%9C-XML-%ED%8C%8C%EC%8B%B1%ED%95%98%EA%B8%B0-%EC%82%BD%EC%A7%88
https://medium.com/@sameerzinzuwadia/android-kotlin-xml-parsing-with-retrofit-6879401d7901
https://github.com/Tickaroo/tikxml/blob/master/docs/AnnotatingModelClasses.md
https://bb-library.tistory.com/177
https://jjjhong.tistory.com/46
https://cjw-awdsd.tistory.com/16
