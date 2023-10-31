---
title: "[데이터베이스] Transaction #3 Transaction 실제 적용"
categories:
- DataBase
tags:
- Study
toc: true
toc_sticky: true
toc_label: 목차
---

이번에는 트랜잭션을 실제로 이용해보는 예를 공부한내용을 정리해보겠다.

# DBMS 에서의 Transaction 적용
---
오라클의 SQL Developer(SQD)에서 transaction은 하나의 갱신연산(insert,update,delete)를 수행할때 마다 transaction이 묵시적으로 시작되고, commit 혹은 rollback을 호출하면 종료된다.

명시적으로 호출하기 위해서는 set transaction name '트랜잭션이름' 을 명시적으로 호출하여 트랜잭션을 시작할수있다.

그리고 갱신연산이나 검색을 수행할때 호출한 연산들을 테이블내의 행(Tuple)단위로 lock을 걸고, commit 이나 rollback을하면 트랜잭션이 종료되면서 unlock이 수행된다.

행단위? 라는것에 대한 구체적인 예시를 살펴보자

```
set transaction name 'T1' -> 트랜잭션의 명시적 시작
update 고객 set 고객이름 = '진호' where 고객아이디 = 'jowunnal' 
commit -> 트랜잭션 종료
```

여기에서 lock이 수행되는 행(Tuple)은 고객아이디가 'jowunnal' 인 튜플이다.

따라서 다른 트랜잭션에서 고객아이디가 jowunnal 인 튜플에 동시에 접근하게 되면 해당 T1 트랜잭션이 종료될때 까지 __대기__ 한다.

또한, 동일세션에서는 set transaction 구문으로 두개이상의 트랜잭션을 시작하면 오류가 발생한다.

테스트를 하기 위해서는 SQD를 하나더 실행해서 다른 세션에서 각각 set transaction으로 트랜잭션을 명시적으로 실행시켜서 테스트 하면 된다.

# JDBC Programming
---
자바 프로그램에서 DB를 연결하기 위해서는 몇가지 추가적인 작업을 더 해주어야 한다.

먼저 해당 DBMS의 Driver를 다운받아 import 해주어야 한다. 이는 자바와 DBMS를 연결하기 위해 필요한 표준 API를 제공해주는 드라이버 이다.

DBMS마다 각각의 공식 사이트에서 JDBC Driver를 다운받은후 자바 프로젝트의 import 경로내에 오라클의경우 ojdbc.jar을 이동시킨후 

두가지 방법으로 드라이버를 Load 해주어야 한다.

1. 환경변수를 추가하는 방법
2. 자바 프로그램내에서 Class.forname() 메소드를 이용하는 방법

환경변수의 경우는 생략하고, 자바프로그램내에서 class.forname() 메소드의 파라미터로 오라클의 경우 "oracle.jdbc.oracleDriver" 을 넣어주고 드라이버를 load한다.

드라이버를 Load하는 작업은 프로그램이 실행될때 한번만 해주면 된다.

드라이버를 load한후 DriverManger.getConnection(url,id,pw) 를 호출하여 url에는 db의 해당 포트주소, id는 오라클의 계정과 pw는 비밀번호를 파라미터로 받아온다.

그리고 반환되는 Connection 객체를 통해 데이터베이스에 접근할수 있다.

데이터베이스에는 연결될수 있는 사용자의 수가 일정수만큼 정해져있고, 여러 사용자가 동시에 많은 인원이 접속하기 위해서는 원하는 작업이 필요할때 마다 Connection 객체를 열고, 사용이 모두 끝나면 Connection 객체의 close() 메소드를 호출하여 닫아주어야 한다.

즉, 사용할때 호출하고 사용이끝나면 닫아주어야 하므로 DriverManager.getConnection()을 호출하는 작업을 메소드로 분리해놓고 SQL문을 호출하는 메소드의 맨처음에 호출하고 사용이 끝나면 close()로 닫아주는 방식으로 사용하여야 한다.

## SQL문 사용
SQL문을 사용하기 위해서는 Statement 객체를 생성하여야 한다.

Statement객체는 3가지로 분류되는데 Statement, PreparedStatement, CallableStatement가 있다. Statement를 상속받는게 PreparedStatement고 , PreparedStatement를 상속받은게 CallableStatement이다.

# Statement ?
---
Statement 객체는 위에서 만들었던 Connection 객체의 createStatement()을 호출하여 생성할수 있다.

그리고 해당 Statement객체에 executeQuery(sql) 메소드로 파라미터에 있는 문자열의 sql문인 select문을 수행하거나, executeUpdate(sql) 메소드를 호출하여 insert,update,delete 연산을 수행할수 있다. 

executeQuery()의 반환값은 ResultSet객체인데 이는 오라클에서의 Cursor에 해당한다. ResultSet 객체로 받아 getXXX() 메소드를 통해 (XXX는 type) 해당 select문의 튜플들을 속성 하나하나에 따라 반환받을수 있다. 파라미터로 숫자를 넣으면 해당인덱스의 위치에 해당하는 속성값을 가져올수있고, 속성명을 명시하면 해당속성의 값을 가져올수도 있다.

ResultSet객체는 Cursor에서 사용하듯이 next()메소드를 호출하여 다음튜플을 가리키게 할수있다. 하지만 주의할점은 ResultSet객체를 맨처음 가져오면 테이블자체를 가리키고 있기 때문에 반드시 Resultset.next()를 한번호출하고 getXXX()로 해당 속성의 데이터를 가져와야만 한다.

물론 보통 while(rs.next) { To do ... } 형식으로 사용하기 때문에 실수를 잘 하지는 않는다.

executeUpdate()의 반환값은 처리된 행의 개수가 int타입으로 반환된다.

또, execute(sql) 문으로 파라미터로 sql문을 넣으면 해당 반환값으로 select문이 sql문으로 들어갔다면 True가 반환되고, insert,update,delete문이 sql문으로 들어갔다면 false가 반환된다.

사용이 끝나면 ResultSet객체와 Statement객체를 close()메소드를 호출하여 닫아주어야 한다.

# PreparedStatement ?
---
PreparedStatement는 위에서 설명햇듯이 Statement를 상속받아 만들어진 클래스다. 

둘의 차이점은 뭘까?

Statement의 경우 sql문을 문자열 처리하여 where 조건에 해당하는 변수를 R-value로 집어넣을때 __where = '"+변수+"'__ 와 같은 형식으로 사용한다.

이는 질의문의 구성이 복잡하다는 단점이 있다.

또한, 해당 질의문이 문자열처리 되어 있고 미리 컴파일하지 않는 구조이기 때문에 Run Time이 되어서야 질의문에 오류가 있는지 없는지 확인할수 있다.

실행시킬때 마다 질의문을 해석하기 때문에 속도가 느리다는 단점역시 존재한다.

PreparedStatement는 이러한점을 보완한 클래스이다.

Connection객체의 prepareStatement() 메소드로 호출하고 파라미터로 sql문을 여기서 집어넣는데 where조건에 해당하는 것들을 __where = ?__ 형태로 문자열 처리하여 넣는다.

그리고 PreparedStatement객체의 setXXX() 메소드를 호출하여 첫번째 매개변수로 ?의 위치를 맨앞부터 차례대로 1,2,3,4 숫자번호 형식으로 넣고, 두번째 매개변수로 해당조건에 들어갈 변수인 R-value를 집어넣는다.

즉 아래와 같은 형태이다.

```
PreparedStatement pstmt = con.prepareStatement('update 학생 set 이름='진호' where 학번 = ?');
pstmt.setInt(1,학번값);
```

이러한 점을 통해 질의문 구성이 단순해지며, 질의문을 미리 컴파일하는 구조 이기 때문에 컴파일타임에 에러가 있는지 확인할 수 있다는 점이 있으며 속도가 빠르다는 장점이 있다.

그외의 executeQuery()나 executeUpdate() 등등은 Statement와 동일하다.

# CallableStatement ?
---
CallableStatement는 PreparedStatement를 상속받기 때문에 그장점들을 모두 사용함과 동시에 DBMS에 존재하는 저장프로시저,함수,패키지 등의 객체를 호출할때 사용한다.

```
CallableStatement cstmt = con.prepareCall("{call 저장프로시저이름(?,?,?)}");
cstmt.setInt(1,변수);
cstmt.registerOutParameter(2,Types.Integer);
cstmt.registerOutParameter(3,OracleTypes.Cursor);
cstmt.executeQuery();
Int a = cstmt.getInt(2);
ResultSet rs = (ResultSet)cstmt.getObject(3);
while(rs.next){
	To do..
}
```

예제에 많은내용을 넣어보았다.

먼저 Connection객체의 prepareCall() 메소드를 호출하여 sql문을 파라미터로 넣고 수행한다. sql문은 저장프로시저 이름을 call 이름 형식으로 가져오고, 해당 저장프로시저의 매개변수를 ? 로 넣어 가져오도록 했다.

저장프로시저의 파라미터의 첫번째는 in 형식이고, 두번째는 out 형식의 number값이고, 세번째는 out형식의 Cursor이다.

첫번째형식은 위에서 설명한 preparedStatement랑 겹치기 때문에 생략하고, out파라미터의 경우 L-value에 해당하기 때문에 registerOutParameter() 메소드로 받아온다.

매개변수 첫번째값은 ? 의 위치이고, 두번째값은 해당 저장프로시저의 두번째 매개변수의 타입이다. number값이기 때문에 자바의 Integer를 타입으로 지정하면 알아서 가져온다.

세번째 out파라미터의 경우 저장프로시저에서 cursor를 out 파라미터로 설정했을 경우이다. 이것은 자바내에서 cursor에 해당하는 타입이 없기때문에 OracleTypes.Cursor로 명시한다.

프로시저 호출은 select와 같은 executeQuery()를 수행하여 호출하고, 해당 out파라미터의 값을 가져오기위해 CallableStatement의 getXXX() 메소드를 사용한다.

Cursor의 경우 가져올때 ResultSet타입으로 변환하여 해당 커서가 가리키는 테이블의 튜플들을 하나씩 가져와서 사용하면 된다.

CallableStatement의 장점은 앞서 [plsql](https://jowunnal.github.io/database/plsql/ "link")에서 설명햇듯이 비즈니스로직이 서버에 존재하기 때문에 보안이 높다는 점 클라이언트가 단순하다는 점과 서버로 전송하는 데이터의 양이 적기 때문에 트래픽이 적다는 장점이 있다.

하지만 서버에서 로직이 동작하면서 서버의 부하는 증가하게 된다. 

또 PrepareStatement의 장점을 그대로 가져 질의문을 미리 컴파일하기 때문에 질의문구성이 쉽고, 에러검출을 컴파일타임에 알수있다는 점이 있으며 자주실행하는 기능일수록 속도가 빠르다는 장점이 있다.

마찬가지로 모든 사용이 끝나면 cstmt.close()를 호출하여 리소스를 제거해주어야 한다.

정리해보자면,

1. JDBC를 Class.forname() 혹은 환경변수 설정으로 Load해온다.
2. DriverManager.getConnection(url,id,pw) 로 DB와 자바프로그램을 연결한다.
3. 연결된 Connection객체로 질의문을 수행하기위해 Statement객체를 생성한다.
4. 질의문을 execute()문으로 수행한다.
5. 수행결과를 ResultSet 혹은 처리된행의개수 로 처리해준다.
6. 리소스를 모두 제거한다.

# Java Programming 에서의 Transaction 적용
---
자바 프로그램에서는 묵시적으로 AutoCommit 방식이기 때문에 하나의 갱신연산을 Transaction 하나로 처리한다. 

명시적으로 트랜잭션을 처리하기 위해서는 Connection객체의 setAutoCommit(false)를 호출해야 한다.

이후 갱신연산을 수행하기 위해 statement객체를 생성하고 Statement객체의 addBatch(sql)로 sql문 하나하나에 대해서 트랜잭션에 추가한다.

praparedStatement를 사용할 경우 prepareStatement(sql)로 sql문을 구성시킨뒤 sql문의 ? 조건들에 대해서 pstmt.setXXX()로 설정하고 나서 addBatch()를 수행하면 된다.

그리고 모든 갱신연산들을 추가했다면 Statement객체 혹은 preparedStatment객체의 executeBatch()로 한번에 트랜잭션을 수행시킨다.

이때 반환되는 값은 int 배열타입으로 반환되는데 addBatch()로 집어넣은 sql문 순서대로 배열인덱스 0부터 시작하고, 해당 배열의 값으로 처리된 행의개수가 반환된다.

마지막으로 갱신연산들을 수행하고 나서 Connection객체의 commit() 혹은 rollback()을 호출하면 트랜잭션이 종료된다.

검사점회복기법인 CheckPoint를 적용시킬수도 있다. 

원하는 위치에 Connection 객체의 setSavePoint()메소드를 호출하여 savepoint를 지정한다.

이후 rollback() 의 파라미터로 함수중복으로 구성된 SavePoint 객체의 값을 집어넣어 생성된 SavePoint 객체 이후의 내용부터 회복이 필요하면 수행하게 된다.

```
con.setAutoCommit(false);
Preparedstatement pstmt = con.prepareStatement(sql);
pstmt.setInt(1,변수);
pstmt.setString(2,'값');
pstmt.addBatch();
SavePoint savepoint = con.setSavePoint();
pstmt.setInt(1,변수2);
pstmt.setString(2,'값2');
pstmt.addBatch();

int[] results = pstmt.executeBatch();
for(i=0;i<results.size;i++);
	System.out.println(result[i]);

con.rollback(savepoint);
con.commit();
```
