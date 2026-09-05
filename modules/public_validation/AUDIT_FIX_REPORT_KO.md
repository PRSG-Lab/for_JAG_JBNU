# v2.1 `RUN_PACKAGE_AUDIT` 실패 진단 및 v2.2 수정 보고서

## 판정

v2.1 실행은 자료 파싱, 경로 추출, 독립 분할, 공분산 보정, held-out 평가 및 단위시험까지 완료되었습니다. 최종 실패 원인은 `package_integrity_audit.m`의 함수 선언 정규식이 `[out1,out2] = function_name(...)` 형태를 해석하지 못한 데 있습니다.

보고서에서 함수명이 빈 문자열로 기록된 9개 파일은 모두 유효한 다중 출력 함수였습니다. 따라서 이 항목은 실제 함수명 불일치가 아니라 감사기의 false negative입니다.

## 수정

- 다중 출력 대괄호에 의존하지 않고 `=` 오른쪽의 호출 가능 이름을 읽는 `read_primary_function_name.m` 추가
- 주석, 빈 줄, UTF-8 BOM 및 `...`로 이어지는 함수 선언 지원
- 패키지의 모든 루트 진입점과 지원 함수에 대한 선언명 회귀시험 추가
- 감사 inventory에 기대 이름, 검출 이름, 파일 존재, 경로 해석 및 일치 여부 추가
- manifest 밖의 예상하지 않은 `.m` 파일과 중복 callable name 검사 추가
- 한국어 MATLAB에서도 parse/syntax 오류를 fatal로 판정하도록 Code Analyzer 검사 보강
- 실패한 단위시험 이름을 텍스트 보고서에 직접 기록

## 전체 함수 검토에서 함께 수정한 사항

장기 단위명 `millimeter/millimetre`와 `centimeter/centimetre`가 일반 `meter/metre` 조건에 먼저 걸려 환산되지 않던 문제를 수정했습니다. 또한 비유한·음수 공분산 exposure 입력, 유효 관측이 전부 제거된 자료, 잘못된 disjoint-path 모드를 조기에 거부하도록 보강했습니다.

## 확인 절차

MATLAB의 Current Folder를 v2.2 패키지 루트로 설정한 뒤 실행합니다.

```matlab
clear functions
rehash
A = RUN_PACKAGE_AUDIT();
```

다음 항목이 모두 확인되어야 합니다.

```text
Missing files: 0
Function-name mismatches: 0
Resolution errors: 0
Unexpected MATLAB files: 0
Duplicate manifest entries: 0
Code Analyzer fatal messages: 0
Unit tests passed: 1
OVERALL PASS: 1
```
