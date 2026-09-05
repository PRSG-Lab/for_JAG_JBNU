# 심사의견 대응전략

핵심 정리는 유지하되 공개자료 분석을 별도의 empirical layer로 추가한다. 실증 분석은 다음 원칙을 따른다.

1. `Gamma`와 공통 `b` scale은 분리해 식별하지 않는다. `Gamma = 1`로 정규화하고 effective coherent scale을 training cases에서 추정한다.
2. minimax의 자기 목적함수만 보고하지 않는다. held-out reference-route discrepancy, RMSE, MAE, casewise actual squared discrepancy 및 paired bootstrap을 함께 보고한다.
3. calibration과 test terminal-pair cases를 먼저 분리하고 물리 observation edge 공유를 금지한다.
4. reference route는 오차가 없는 참값이 아니다. reference variance를 comparison interval에 포함하고 `reference-route consistency`로 표현한다.
5. 공개자료에서 aggregate minimax가 centroid보다 평균적으로 불리하면 이를 숨기지 않는다. 이는 worst-case protection의 empirical cost로 해석한다.
6. strict node-disjoint 사례와 edge-disjoint fallback 사례를 분리해 보고한다.
7. usable held-out cases가 부족하거나 자료 부호·단위가 불명확하면 실증결과를 본문 근거로 사용하지 않는다.
