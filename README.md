# RISC-V RV32I CPU Design

## 1. Project Overview
본 프로젝트는 시스템반도체 설계를 위한 RISC-V RV32I 기반의 CPU 구현 프로젝트입니다.
SystemVerilog를 활용하여 CPU를 설계하고, 시뮬레이션을 통해 각 명령어 Type별 신호와 데이터 흐름을 깊이 있게 이해하는 것을 목적으로 합니다. 
설계된 CPU는 직접 작성한 Assembly 코드를 통해 누적합 연산을 수행하며 정상 동작을 검증했습니다.

## 2. Tech Stack
| Category | Details |
| :--- | :--- |
| **S/W Environment** | Vivado 2020.2, VS Code, GCC |
| **Language** | SystemVerilog, Assembly |
| **Target Architecture** | RISC-V Base Integer Instruction Set (RV32I) |

## 3. Architecture & Modules
프로젝트는 크게 명령어 메모리(Instruction Memory), 데이터 메모리(Data Memory), 그리고 CPU 코어(Control Unit + Datapath)로 구성되어 있습니다.

*   **Control Unit (`control_unit`)**: 
    *   명령어의 `opcode`, `funct3`, `funct7`을 해독하여 데이터패스를 제어하는 핵심 신호(`alu_control`, `rf_we`, `jal` 등)를 생성합니다.
    *   FETCH, DECODE, EXECUTE, MEM, WB의 상태(State)를 가지는 FSM(Finite State Machine) 구조로 설계되었습니다.
*   **Datapath (`rv32i_datapath`)**:
    *   **ALU**: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` 등 R-type의 연산 및 분기(Branch)를 위한 조건 판단을 수행합니다.
    *   **Register File**: 32개의 32-bit 레지스터로 구성되며, 비동기 읽기 및 동기 쓰기를 지원합니다.
    *   **Immediate Extender**: 각 명령어 타입(I, S, B, U, J)에 맞추어 Immediate 값을 32-bit로 확장합니다.
    *   **Program Counter**: 분기 및 Jump 명령어에 따른 다음 실행 주소를 계산하여 갱신합니다.

> Block Diagram
> <img width="1162" height="811" alt="RV32I_RSIBUJ" src="https://github.com/user-attachments/assets/2db1adbf-10a9-457f-9881-17723a24fb07" />

## 4. Supported Instruction Types
설계된 CPU는 다음과 같은 RISC-V RV32I 핵심 명령어 타입을 지원합니다.

| Type | Instructions | Description |
| :--- | :--- | :--- |
| **R-Type** | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` | 레지스터 간의 산술 및 논리 연산 수행 |
| **I-Type** | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` | 레지스터와 Immediate 값 간의 연산 수행 |
| **S-Type** | `SW`, `SH`, `SB` | 레지스터의 값을 메모리에 저장 (Word, Half-word, Byte) |
| **I_L-Type**| `LW`, `LH`, `LB`, `LHU`, `LBU` | 메모리의 값을 레지스터로 로드 및 부호 확장 |
| **B-Type** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | 조건 성립 시 지정된 주소로 분기 (Branch) |
| **U-Type** | `LUI`, `AUIPC` | 32비트 상위 상수를 레지스터에 로드하거나 PC에 더함 |
| **J-Type** | `JAL`, `JALR` | 지정된 주소로 점프하고 복귀 주소를 저장 (Jump and Link) |

## 5. Verification: Assembly Execution
설계한 CPU의 종합적인 동작을 검증하기 위해 C 코드로 작성된 누적합(1부터 10까지 더하기) 로직을 RISC-V Assembly 코드로 변환하여 시뮬레이션을 수행했습니다.

*   **Test Scenario**: `while` 루프를 순회하며 `adder` 함수를 호출하여 값을 누적.
*   **Result**: 레지스터 `x10` (또는 `a0`)에 최종 누적합 결과인 `55` (Hex: `0x37`)가 정상적으로 연산 및 저장되는 것을 파형으로 확인했습니다.

> Simulation Waveform
> <img width="2924" height="590" alt="image" src="https://github.com/user-attachments/assets/57313171-e3c5-4a88-b2dc-6417f562e6e9" />


## 6. Trouble Shooting
개발 과정에서 발생한 주요 문제와 해결 전략입니다.

*   **Race Condition in Data Memory (Load/Store)**
    *   **문제 상황**: Store(S-type)와 Load(I_L-type)가 모두 `clk`에 동기화된 Non-blocking 할당(`<=`)으로 처리될 때, Race Condition이 발생하여 시뮬레이션 상에서 `X` (Unknown) 값이 나타나는 현상을 확인했습니다.
    *   **해결 방안**: Load(`I_L` type) 동작을 비동기식 조합 회로(`always_comb`)로 분리하여 데이터를 즉시 읽어오도록 수정함으로써 Race Condition을 방지하고 정상적인 데이터 로드가 가능하게 설계했습니다. 

## 7. Author
*   **강동우 (Kang Dong-woo)**[cite: 8]
