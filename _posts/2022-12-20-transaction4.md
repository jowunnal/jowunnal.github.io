---
title: "[데이터베이스] Transaction #4 고립수준"
categories:
- DataBase
tags:
- Study
---

앞서 [Transaction #1](https://jowunnal.github.io/database/transaction1/ "link")와 [Transaction #2](https://jowunnal.github.io/database/transaction2/ "link") 에서 회복과 병행제어에 대해서 정리해 보았다.

마지막은 T1+T2가 Read+Write의 경우에서 발생하는 __현상__ 이다.

Write+Write에서는 발생하는 __문제__ 라고 얘기했고 갱신분실,모순성,연쇄복귀 의 문제점들을 지키기 위해 2PL을 이용한다고 했었다.

이것들은 반드시 해결해야하는 문제점들 이었다.

하지만 Read+Write에서 발생하는 것은 문제가 아니라 __현상__ 이다. 즉 문제점은 아니라는 것이다.

왜그런지 살펴보자.

# Read+Write의 현상들
---
Read+Write에서 발생하는 현상은 다음 3가지와 같다.

1. Dirty Read 
2. Non-Repeatable Read
3. Phantom Read

### Dirty Read
Read UnComitted (커밋하기 전에도 데이터를 읽을수 있는 경우)에서 T2가 데이터를 write 한채로 부분완료 상태일때 (물리적연산들을 모두 수행하고 commit 혹은 rollback을 호출하기 직전의상태) T1이 데이터를 읽었다고 가정해보자.

T2가 commit을 수행하면 T1은 재대로된 데이터를 읽은 셈이다.

하지만 T2가 rollback을 수행하면 T1은 잘못된 데이터를 읽은 셈이된다.

이처럼 T2의 수행에 따라 T1의 읽기작업이 잘못될수도 잘된것일수도 있는 __현상__ 이 발생하게 된다.

이는 T1이 읽기를 수행한 시점이 억울하게도 T2가 아직 부분완료 일때 읽어서 발생하게 된다.

즉, 다시 T1이 읽기를 수행한다거나 T2가 완료상태에서 읽엇을 경우에는 발생하지 않는다.

이러한점을 고려하여 학계에서도 의견이 분분하다고 하지만.. 교수님께서는 이를 __현상__ 이지 문제는 아니다 라고 말씀하셨다.

또한 이러한점들을 허용 할것인지 비허용 할것인지는 사용자 즉, DBA가 결정하게 하는것이 좋다는 것이고 이를 __고립수준__ 설정 이라고 한다.

물론, Oracle에서는 기본적으로 Read Committed 방식이기 때문에 commit된 내용만 다른세션에서 읽을수 있어 default로 dirty read를 허용하지 않는다.

이 수준을 고립수준 1단계 라고 한다. ( 0,1,2,3,4 단계가 존재함)

### Non-Repeatable Read
Non-Repeatable Read는 T1이 반복해서 읽기 작업을 수행하는 도중에 T2가 데이터를 변경(update)한 경우이다.

```
set transaction name 'T1'
select 학번 from 학생 where 고객이름 = '진호' --> 학번=2017

		set transaction name 'T2'
		update 학생 set 학번 = '2016' where 고객이름='진호'

select 학번 from 학생 where 고객이름 = '진호' --> 학번=2016
```

이경우 dirty Read와는 달리 T2가 commit을 했을때 수행시점을 달리하였을때 앞선시점과 이후시점의 결과값이 달라서 T1의경우 앞선시점에 읽은 데이터가 잘못된 데이터가 되버린다.

하지만 이또한 수행시점이 달랐을뿐 문제가아니라 __현상__ 이라는 것이다. 나중에 읽은 데이터는 당연히 다를수도 있다는 현상인 것이다.

### Phantom Read
Phantom Read의 경우 T1이 반복읽기를 하던중에 T2가 데이터를 삽입(insert)하여 앞선시점과 이후시점의 데이터가 달라 잘못된 읽기를 했을 경우이다.

```
set transaction name 'T1'
select count(학번) as "학생수" from 학생 --> 학생수:4

		set transaction name 'T2'
		insert 학생(학번,이름) values ('홍길동',2020)

select count(학번) as "학생수" from 학생 --> 학생수:5
```

이역시 dirty Read와는 달리 T2에서 commit을 했을경우, 반복읽기를 하던중에 앞선시점과 이후시점의 읽은 데이터의 값이 달라 이후시점에 없던 데이터가 생기는 유령데이터를 읽은 셈이 되버린다.

서로 시차를 달리해서 읽었을 뿐이지 이또한 문제점이 아니라 그저 __현상__ 일뿐이다.

# 고립수준 설정
---
이러한 현상들을 허용할것인지 비허용할것인지는 사용자인 DBA가 결정할 문제이다.

시차가 달라서 발생한 현상들을 문제라고 보고 무조건 비허용하는 것은 옳지 않다는 것이다.

고립수준의 단계는 다음과 같다.

1. 0단계 : 고립수준을 아에 설정하지 않음
2. 1단계 : Read UnCommitted (상수 1)
3. 2단계 : Read Committed (상수2)
4. 3단계 : Repeatable Read (상수4)
5. 4단계 : Serializable (상수8)

1단계는 dirty read, non-repeatable read, phantom read를 모두 허용하는 수준이다. 얼핏보면 0단계와 비슷하지만 학계에서는 필요하다고 생각해서 이 또한 나누었다고 한다..
2단계는 dirty read는 비허용, non-repeatable read, phantom read 은 허용하는 수준이다.
3단계는  dirty read, non-repeatable read는 비허용 , phantom read 은 허용하는 수준이다.
4단계는 모두 비허용하는 단계이다.

2단계가 oracle의 Default이며 또한 oracle은 Serializable을 지원하고 나머지는 지원하지 않는다.

고립수준이 높아질수록 DBMS의 간섭이 커진다는 것을 의미하기도 한다.

이렇게해서 학부 커리큘럼상 배운 Transaction에 대해서 모두 정리해 보았다.

내용은 상당히 어렵게 보이지만 이해하는데는 어렵지않았다.
