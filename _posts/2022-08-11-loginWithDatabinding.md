---
title: "[Android] 데이터바인딩 사용하여 로그인기능 구현"
categories:
- Android
tags:
- Study
---

이전글 [Retrofit2 로 Api통신하기](https://jowunnal.github.io/android/retrofitWithApi "link") 에서 이어지는 토이 프로젝트 이다.

# 지도에 표현하기
---
먼저, 카카오맵api를 이용하여 공공데이터포털api로 응답받은 데이터들을 지도상에 표현해보았다.

[카카오맵api 가이드](https://apis.map.kakao.com/android/guide/ "link")에서 자세한 카카오맵api의 설명을 참조 가능하다.  카카오맵의경우 지도상에 객체를 표현하려면 marker객체가 필요하다.

```kotlin
fun makeMarker(list:List): MapPOIItem {
        val marker = MapPOIItem()
        val mapPoint= MapPoint.mapPointWithGeoCoord(list.lat!!,list.lng!!)
        marker.itemName = list.company
        marker.mapPoint = mapPoint
        marker.markerType = MapPOIItem.MarkerType.BluePin// 기본으로 제공하는 BluePin 마커 모양.
        marker.selectedMarkerType = MapPOIItem.MarkerType.RedPin // 마커를 클릭했을때, 기본으로 제공하는 RedPin 마커 모양.
        return marker
    }
```

위예제는 공공데이터포털로 부터 받은 리스트값들의 위도,경도를 MapPOIITEM객체를 만들어 할당하여 지도상에 식당들을 객체로 표현하는 function 이다.

MapPOIITEM객체를 가이드에서 marker라고 부른다. 이렇게 만들어진 marker를 mapView에 추가하면 지도상에 표현된다.

```kotlin
val markerList= ArrayList<MapPOIItem>()
        apiViewModel.restaurantList.observe(viewLifecycleOwner, Observer {
            for (data in it){
                markerList.add(apiViewModel.makeMarker(data))
            }
            mapView.setMapCenterPoint(MapPoint.mapPointWithGeoCoord(it[0].lat!!, it[0].lng!!), true)
            mapView.addPOIItems(markerList.toArray(arrayOfNulls(markerList.size)))
        })

        binding.mapView.addView(mapView)
        mapView.setMapCenterPoint(MapPoint.mapPointWithGeoCoord(35.5383773, 129.3113596), true)
        mapView.zoomIn(true)
        mapView.zoomOut(true)
```

필자는 공공데이터포털로 부터 받은 식당여러개의 리스트값들을 몽땅 마커로 만들기위해 markerList에 만들어진 marker들을 할당하고 mapView.addPOIItems()에 할당하였다.

mapView는 간단하게 xml에 만들어진 layout객체를 mapView라는 변수에 할당한것이다.

![지도화면](/assets/tp_RetrofitWithMap_map.PNG)
# Databinding?
뷰와 뷰모델, 그리고 모델 간의 의존성을 줄여서 boilerplate를 줄이고 재사용성을 높이는 MVVM 패턴에서 화면인xml에 직접 선언형방식으로 데이터와 layout을 결합하는 방식으로 사용된다.

여기서 단방향,양방향 바인딩에 대한 개념도 등장한다. 단방향은 layout의 구성요소의 setter만 연결하는방법이고, 양방향은 getter와 setter모두 연결하는 방법이다.

layout구성요소인 editTextView.text="@{user.name}" 으로 선언해두면, user의 이름값이 editTextView에 들어가는방식만 수행이되는데, editTextView.text="@={user.name} 으로 선언해두면 user.name의값이 editTexitView의 text값으로 설정도되지만, editTextView의 값이 변경됨에따라 user.name의 값도 변경되는 양방향데이터결합 방식이 된다.

그렇게하면 훨씬더 boilerplate를 줄이고 가독성이 증가된다는 장점이 있다.

또한, 단순히 객체의값만 할당하는것이 아닌 이벤트핸들러 역시 할당가능하며(=리스너결합), 매개변수가 없을때 또는 하나이상일때 또는 바인딩어댑터 어노테이션으로 생성된 결합 방식과 바인딩메소드 어노테이션으로 메소드이름만 재지정하는 방식이 있다.

필자는 매개변수가없는 방식과 바인딩어댑터를 통한 리스너결합을 사용하였다.

```kotlin
android:onClick="@{()->apiViewModel.getRestaurantData(etCity.getText().toString())}"
```

단순하게 xml상의 onClick이벤트 핸들러에 단방향결합으로 리스너결합을 수행한 모습이다. 내부에 선언된 textView의 string값을 가져와 내부에선언된 apiViewModel의 식당데이터를 가져오는 메소드에 할당하여  apiViewModel에 선언된 livedata에 식당데이터들을 할당해두고, 여기에 observer를등록하여 뷰에서 데이터들이 들어오면 바로 지도상에 marker객체를 생성한다.

```kotlin
fun getRestaurantData(city:String){
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
```

```kotlin
apiViewModel.restaurantList.observe(viewLifecycleOwner, Observer {
            for (data in it){
                markerList.add(apiViewModel.makeMarker(data))
            }
            mapView.setMapCenterPoint(MapPoint.mapPointWithGeoCoord(it[0].lat!!, it[0].lng!!), true)
            mapView.addPOIItems(markerList.toArray(arrayOfNulls(markerList.size)))
        })
```
# 로그인 및 회원가입 기능
---

회원가입기능에서는 양방향 데이터결합과 바인딩어댑터를 사용한 리스너결합을 이용한다.

```kotlin
<com.google.android.material.textfield.TextInputEditText
                android:id="@+id/editTextName"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:hint="닉네임"
                android:ems="10"
                android:onTextChanged="@{register.checkNameIsCorrect}"
                android:inputType="textPersonName"
                android:text="@={user.userName}"
                android:textColor="#6E6C6C"/>
```

text의 값에 user객체의 user.Name이 양방향결합으로 선언되어 user.Name값이 text에할당됨과 동시에 text값이 변경되면 user객체의 user.Name값이 변경된다.

또한, 여기서 생성된 user객체는 View 단에서 User()객체를 생성하여 할당해 주어야함을 잊지말자.  

onTextChanged 리스너에 register객체의 checkNameIsCorrect변수가 결합되어 있는데, 

```kotlin
val checkNameIsCorrect = fun(inputString:String){
        if(inputString.contains(Regex("[^0-9a-zA-Zㄱ-힣_]"))){
            binding.etName.helperText="특수문자(_)를 제외하고 입력될수 없습니다."
        }
        else
            binding.etName.helperText=""
    }
```

Register클래스에 선언되어있는 변수이다. 이는 고차원함수방식으로 사용되기위해 함수형언어인 코틀린에서의 장점이 엿보인다.

```kotlin
@BindingAdapter("android:onTextChanged")
fun onTextChanged(view: TextInputEditText, inputString: (String?)->Unit){
    view.doOnTextChanged { text, start, before, count -> inputString(text.toString()) }
}
```

바인딩어댑터 어노테이션으로 생성되는 어댑터는 반드시 코틀린파일의 클래스외부에 생성되야 한다. 이는 [구글공식가이드](https://developer.android.com/topic/libraries/data-binding/binding-adapters "developers")에서도 설명하듯이 바인딩어댑터는 선언해두엇을때 메모리내에서 정적으로 공유되는 방식이기 때문에 static으로 선언해야 한다. 코틀린의경우 클래스밖에 선언해두면 static임을 보장해주기 때문에 클래스밖에 선언해둔 모습이다. (또는 @JVMStatic 을 사용할수도 있다.)

바인딩어댑터의 방식은 어노테이션의 invoke에 생성할 바인딩어댑터가 결합될 이벤트핸들러의 이름을 지정해주고(없는이름으로 지정하면 이름그자체를 layout 위젯의 필드값으로 사용) 결합된 리스너에서 동작할 function을 선언해주면 실질적으로 sdk에서 자동으로 만들어진 리스너가 수행되는것이 아닌 만들어진 바인딩어댑터의 메소드가 수행된다.

여기에는 몇가지 규칙이있는데, 결합할리스너의 명칭이 위와같이 동일해야하고(xml와 데이터바인딩어노테이션의 invoke이름) 결합할 리스너가 동작되는 위젯객체가 바인딩어댑터 메소드의 첫번째 인자로 와야하며, 리스너내부에서 여러개의 메소드가 override될경우 각각 하나하나 따로 생성하는것이 좋다. 더자세한내용은  [구글공식가이드](https://developer.android.com/topic/libraries/data-binding/binding-adapters "developers")을 참고바란다.

필자가 응용한것으로는 layout에 선언된 리스너결합에 의해 onTextChanged의 메소드로 결합된 바인딩어댑터의 메소드가 호출되고, 이메소드의 inputString인자에 checkNameIsCorrect가 할당된 모습이다. 이를통해 사용자가 입력한 이름에 정규식에따라 숫자,문자,특수문자 언더바 를 제외한 문자가 입력되면 텍스트뷰의 helperText의 값에 입력될수없다는 문구를 띄워준다.

또한 입력된문자열은 양방향 데이터결합을 통해 회원가입 버튼을 눌럿을때 결합된 loginViewModel의 registerUser()기능을 수행하여 내장데이터베이스에 입력된값들을 저장한다.

```kotlin
class LoginViewModel(private val app: Application) : AndroidViewModel(app) {
    private val repository= LoginRepository.getInstance(app.applicationContext)
    var mutableLogFlag = MutableLiveData(false)
    val logFlag: LiveData<Boolean> get() = mutableLogFlag

    fun loginUser(client:User) {
        viewModelScope.launch(Dispatchers.Main) {
            val user= withContext(Dispatchers.IO) { repository.getUser() }
            for(data in user){
                if(client.userId==data.userId&&client.userPw==data.userPw){
                    mutableLogFlag.value=true
                    continue
                }
                else if(client.userId==data.userId&&client.userPw!=data.userPw){
                    Toast.makeText(app,"비밀번호가 일치하지 않습니다.",Toast.LENGTH_SHORT).show()
                    continue
                }
            }
            Toast.makeText(app,"존재하지 않는 아이디 입니다.",Toast.LENGTH_SHORT).show()
        }
    }

    fun registerUser(user:User){
        viewModelScope.launch(Dispatchers.IO) { repository.addUser(user) }
        Log.d("test", "${user.userId} ${user.userPw}")
    }

    fun deleteUser(id:String,pw:String){
        viewModelScope.launch(Dispatchers.IO) { repository.deleteUser(User(id,"jinho",pw)) }
    }

}
```

처음에는 위와같은 방식으로 코드를 작성햇었다. 여기서의 문제점은 로그인을 진행할때도 현재있는 계정인지를 확인하고, 회원가입을 진행할때도 현재있는 계정인지를 확인하는것이다.

즉, 계정이 있는지를 체크하는 부분이 중복되는 현상이 발생하기 때문에 loginUser()의 구현체를 checkUser()로 할당하고 이를 loginUser()와 registerUser() 메소드들에서 재사용하는 방식으로 변경하였다.

```kotlin
class LoginViewModel(private val app: Application) : AndroidViewModel(app) {
    private val repository= LoginRepository.getInstance(app.applicationContext)
    var mutableLogFlag = MutableLiveData(0)
    val logFlag: LiveData<Int> get() = mutableLogFlag

    fun loginUser(client:User){
        viewModelScope.launch(Dispatchers.Main){checkUser(client,"환영합니다.","비밀번호가 틀렸습니다.","존재하지 않는 계정 입니다.")}
    }
    suspend fun registerUser(user:User):Boolean{
        var result=false
        viewModelScope.launch(Dispatchers.Main){
            val job = launch{checkUser(user,"이미 존재하는 아이디 입니다.","이미 존재하는 아이디 입니다.",user.userName+"님의 회원가입이 완료되었습니다.")}
            job.join()
            if(logFlag.value==0) {
                repository.addUser(user)
                result=true
                Log.d("test", "${user.userId} ${user.userPw}")
            }
            mutableLogFlag.value=0
        }.join()
        return result
    }

    fun deleteUser(id:String,pw:String){
        viewModelScope.launch(Dispatchers.IO) { repository.deleteUser(User(id,"jinho",pw)) }
    }

    suspend fun checkUser(client:User,succeedText:String,wrongText:String,notFoundText:String) {
        val user= withContext(Dispatchers.IO) { repository.getUser() }
        for(data in user){
            if(client.userId==data.userId&&client.userPw==data.userPw){
                mutableLogFlag.value=1
                Toast.makeText(app,succeedText,Toast.LENGTH_SHORT).show()
                return
            }
            else if(client.userId==data.userId&&client.userPw!=data.userPw){
                mutableLogFlag.value=2
                Toast.makeText(app,wrongText,Toast.LENGTH_SHORT).show()
                return
            }
        }
        if(logFlag.value==0){
            Toast.makeText(app,notFoundText,Toast.LENGTH_SHORT).show()
        }
    }
```

이미존재하는 아이디와 비번인지를 체크하면서 발생되는 Toast메세지역시 매개변수로받아 문구를 달리했고, 각각의 결과값에따라 내부livedata변수의 값을 변경시켜서 이값에따라 loginUser()와 registerUser()의 서로다른점을 제어해 주었다.  login의경우 아이디와 비밀번호가 모두 같아야 로그인성공 메세지와함께 화면이 전환되고, 아이디가다르면 없는계정이며 비번이다르면 비번이다름을 메세지로 보여주어야 했다.

하지만 회원가입의 경우 아이디가같은것이 있으면 가입이불가능하고, 아이디가 다르면 가입이 가능한 구조이므로 login과 정반대의 규칙이다.

이두가지의 내부로직은 같은로직을 수행하지만 정반대의 결과값을 필요로하므로 내부에 livedata의 변수값을 할당하고 이를통해 제어하는 방식으로 작성했다.

더불어서 회원가입의 registerUser()메소드가 suspend인 이유는 화면인 View 단에서 회원가입이 성공이라면 화면을 로그인화면으로 전환하여야 하는데, 여기서 논리적 문제점이 발생한다.

만약, 사용자가 회원가입을하는데 아이디가 달랐다고 해보자. 그러면 메소드로직에 따라 livedata값이 1로바뀐다. 이상태에서 로그인화면으로 돌아가면 livedata가 1이기때문에 로그인화면에서 홈 화면으로 navigate된다.

```kotlin
loginViewModel.logFlag.observe(viewLifecycleOwner, Observer {
            if(it==1){
                Navigation.findNavController(view).navigate(R.id.action_log_to_home)
                loginViewModel.mutableLogFlag.value=0
            }
        })
```

앞서보여졌던 코드에서 로그인이성공이면 livedata값이 1이 되기때문에 observer가 1이면 자동으로 홈화면으로 전환시키게 구현했기 때문이다.

여기서 논리적문제점이 발생하기 때문에 같은아이디가 입력되고 뒤로가기를 해도 로그인화면에서 홈화면으로 전환하지 않으려면 livedata값을 0으로 만드는 수밖에 없다.

그래서 registerUser()의 마지막줄에 livedata의값을 0으로 만들고 코루틴에 의해 스레드가 새로할당되어 결과값을 정확하게 반환하기 위해서 suspend 메소드로 선언하고 View단에서 결과값을 받아 처리하도록 한것이다. (suspend로 하지않으면 로직상 registerUser()의 결과값은 false만 리턴된다. 내부 코루틴블럭과 비동기적으로 동시에 수행되기때문)

```kotlin
binding.btnSignUP.setOnClickListener {
            if(binding.editTextName.text.isNullOrEmpty()|| binding.editTextID.text.isNullOrEmpty()||binding.editTextPW.text.isNullOrEmpty()||binding.editTextPWCheck.text.isNullOrEmpty()){
                Toast.makeText(requireActivity(),"작성하지 않은 항목이 있습니다.",Toast.LENGTH_SHORT).show()
            }
            else if(binding.etName.helperText?.isNotEmpty() == true || binding.etID.helperText?.isNotEmpty() == true ||
                binding.etPW.helperText?.isNotEmpty() == true || binding.etPWCheck.helperText?.isNotEmpty() == true) {
                Toast.makeText(requireActivity(),"올바른 형식으로 입력되지 않았습니다.",Toast.LENGTH_SHORT).show()
            }
            else{
                lifecycleScope.launch(Dispatchers.Main) {
                    val result= withContext(Dispatchers.IO){loginViewModel.registerUser(user)}
                    if(result) {
                        Navigation.findNavController(view).popBackStack()
                        Log.d("test", user.toString())
                    }
                }
            }
        }
```

else구문을 보면 같은 코루틴(스레드)상에서 결과값을 전달받아서 처리하여야 정확히 전달받은값으로 화면을 전환할지 결정한다.

위의 if문과 elseif문의경우 회원가입화면에서 입력된 문자들의 형식이 올바른지에 대한 제어문이다. 작성하지않은 항목이 잇거나 올바르지않은 항목이 있는경우 회원가입을 할수없도록 제어했다.

![잘못된형식일때](/assets/tp_RetrofitWithMap_wrongSentence)

주어진 조건들에 부합하지 못하는 형식이 입력됬을때 helperText로 문구를 보여주고, 회원가입을 할수없다.

![올바른형식일때](/assets/tp_RetrofitWithMap_correctSentence)

올바르게 입력했다면 회원가입이 가능하다.

![로그인화면](/assets/tp_RetrofitWithMap_login)

로그인화면이다.

[깃허브주소](https://github.com/jowunnal/TP_RetrofitWithMap "github link") 에 모든 코드들을 확인할수 있다.
# References
---
(데이터바인딩)

https://developer.android.com/topic/libraries/data-binding/binding-adapters

https://devvkkid.tistory.com/203

https://myung6024.tistory.com/100

https://salix97.tistory.com/246

https://yoon-dailylife.tistory.com/113

(카카오맵)

https://charbroiled.rexalcove.com/64 

https://creaby.tistory.com/11

https://onedaythreecoding.tistory.com/entry/AndroidKotlin-KakaoMap%EC%B9%B4%EC%B9%B4%EC%98%A4%EB%A7%B5-API-%EC%A7%80%EB%8F%84-%EC%A2%8C%ED%91%9C-%EB%9D%84%EC%9A%B0%EA%B8%B0-%EB%A7%88%EC%BB%A4-%ED%91%9C%EC%8B%9C-MapPoint

https://apis.map.kakao.com/android/guide/
