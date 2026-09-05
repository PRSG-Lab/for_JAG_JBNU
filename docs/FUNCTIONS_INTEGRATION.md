# 통합 실행·검증 함수 명세

| 파일 | 호출 형식 | 설명 |
|---|---|---|
| `RUN_JAG.m` | `info = RUN_JAG(action,cfg)` | 작업명과 선택 경로 설정을 받아 모듈을 실행하고 결과 위치를 반환한다. 종료·오류 시 path, 현재 폴더, RNG를 복원한다. |
| `JAG_CONFIG.m` | `cfg = JAG_CONFIG()` | 현재 패키지 위치를 기준으로 입력·출력 기본 경로 네 개를 만든다. |
| `+jag/validate_config.m` | `cfg = jag.validate_config(cfg,root)` | 네 경로 필드만 허용하고 패키지 루트 일치 및 경로 형식을 확인한다. |
| `+jag/absolute_path.m` | `value = jag.absolute_path(value)` | 상대 경로를 MATLAB의 현재 폴더를 기준으로 절대 경로로 바꾼다. |
| `+jag/restore_environment.m` | `jag.restore_environment(state)` | 저장된 작업 폴더·난수 상태·검색 경로를 복구한다. 직접 실행할 필요가 없다. |
| `+jag/gsvs_options.m` | `cfg = jag.gsvs_options(cfg,options,stage)` | GSVS17 단계별 입력·출력 경로만 덮어쓰고 분석·그림 설정 변경은 거부한다. |
| `+jag/new_run.m` | `runDir = jag.new_run(outputDir,kind)` | 기존 결과와 충돌하지 않도록 시각과 임시 고유 이름을 조합한 결과 폴더를 만든다. |
| `+jag/write_json.m` | `jag.write_json(file,value)` | 구조체 등을 UTF-8 JSON 파일로 저장하고 파일 핸들을 닫는다. |
| `+jag/run_gsvs17.m` | `info = jag.run_gsvs17(cfg)` | GSVS17 baseline과 addendum을 차례로 실행하고 두 MAT·원래 그림 세트·최종 그림 모음을 보관한다. |
| `+jag/run_public.m` | `info = jag.run_public(cfg,mode)` | 공개검증 모듈에 공통 raw/runs 경로를 전달한다. 통합 manifest를 추가한 뒤 결과 ZIP도 갱신한다. |
| `+jag/sha256.m` | `hash = jag.sha256(file)` | 로컬 파일의 SHA-256을 JVM으로 계산한다. 대용량 파일은 나누어 읽는다. |
| `+jag/verify_sources.m` | `report = jag.verify_sources(root)` | 배포 manifest의 MATLAB·입력 파일 해시를 대조하고 변경·누락 파일을 반환한다. |
| `+jag/audit.m` | `report = jag.audit(cfg)` | 소스 무결성, 공개 모듈의 기존 검사와 통합 회귀시험을 수행한다. 모듈 사본에서 감사해 배포 소스를 수정하지 않는다. |
| `+jag/selftest.m` | `info = jag.selftest(cfg)` | 공개 합성 fixture의 전체 실행과 GSVS17 파싱·왕복쌍·M0/M1 적합을 검사한다. GSVS17 전체 프로파일/부트스트랩은 별도 실행이다. |
| `tests/integration_tests.m` | `report = integration_tests(cfg)` | 대소문자 필드명 처리, 상대 경로, 그림 기본값 보존, 허용되지 않은 설정 거부를 회귀검사한다. |
