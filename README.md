# 접속 주소
http://springboot-alb-1545096277.ap-northeast-2.elb.amazonaws.com/

# 레포지토리 구조
```
├── README.md
├── k8s-manifest : 쿠버네티스에 배포한 리소스의 명세입니다.
│   ├── lb_controller
│   │   └── values.yaml
│   └── springboot
│       ├── deployment.yaml
│       ├── ingress.yaml
│       └── service.yaml
└── terraform : AWS 환경을 배포한 테라폼 코드입니다.
    ├── networks : 네트워크 tf파일을 관리합니다.
    │   └── prd
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── platforms : 컴퓨팅 리소스 tf파일을 관리합니다.
    │   └── prd
    │       └── eks-241124
    │           ├── main.tf
    │           └── outputs.tf
    └── security : 보안 리소스 tf파일을 관리합니다.
        └── prd
            └── main.tf  
```

# 요약
- 디렉토리 구조는 {리소스계열}/{환경}/main.tf 를 기준으로 합니다.

- EKS는 하위 디렉토리를 두고 다른 리소스와 분리합니다.

  - EKS 테라폼 코드는 매번 plan에서 변경점 발생빈도가 매우 높은 편에 속합니다. 다른 리소스 코드와 함께 위치하는 경우, 간단한 작업을 반영하기 위해 발생하는 모든 변경점을 체크하고 코드 sync를 맞춰야 하는 불편함이 있고, 실수로 변경점이 반영되지 않거나 destroy되는 경우 크리티컬하므로 격리합니다.

  - blue/green 업그레이드상황이나 멀티 클러스터를 테라폼으로 관리하는 상황을 고려하면 EKS는 클러스터 단위로 코드를 분리시켜 두는 것이 합리적이라고 생각했습니다.

- IRSA대신 Pod Identity를 사용하며, 이는 EKS와 연결되지만 보안 리소스로 취급하여 security 디렉토리에서 관리합니다.

  - 구성이 훨씬 간결하고 테라폼으로 생성이 가능합니다.

  - 단, 쿠버네티스 오브젝트인 Service Account가 먼저 생성된 후 -> Pod Identity를 테라폼에서 정의해야 하므로, 파이프라인에 대한 고민이 필요합니다.

  - 궁금해서 사용해보았어요.

# 개선하고 싶은 점
- vpc 공식 모듈의 사용성이 좋지 않아, 우리 서비스에 맞는 네트워크 표준 모델을 세우고 커스텀 모듈을 만드는 편이 좋아 보여요.(모듈 코드를 다 열어보지 않으면, count를 사용하여 인덱스 기반으로 subnet/zone을 맞춰주어야 함)

- 테라폼 파일들은 작업자가 아닌 시스템에 의해 반영되도록 하고, PR기반으로 트리거+승인절차를 추가하면 코드 전반에 대한 퀄리티를 끌어올릴 수 있어요.

- 
