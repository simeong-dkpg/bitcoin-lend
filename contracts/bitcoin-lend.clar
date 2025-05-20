;; Bitcoin Lend: Secure Lending Protocol for Stacks Blockchain
;;
;; A decentralized lending protocol built on Stacks, designed for Bitcoin
;; compatibility with Layer 2 optimizations. This contract enables users to
;; deposit STX as collateral, borrow against their collateral, and earn 
;; interest by providing liquidity to the protocol.
;;
;; Features:
;; - Collateralized borrowing with configurable ratios
;; - Dynamic interest calculation based on block height
;; - Automatic liquidation mechanism
;; - Protocol fee collection system
;; - Emergency pause functionality

;; Constants & Error Codes

(define-constant CONTRACT-OWNER tx-sender)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-INVALID-AMOUNT (err u403))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u404))
(define-constant ERR-LOAN-NOT-FOUND (err u405))
(define-constant ERR-LOAN-ALREADY-EXISTS (err u406))
(define-constant ERR-MATH-OVERFLOW (err u407))
(define-constant ERR-LOAN-NOT-LIQUIDATABLE (err u408))
(define-constant ERR-LOAN-NOT-REPAYABLE (err u409))
(define-constant ERR-INVALID-LOAN-ID (err u410))

;; Configuration constants
(define-constant COLLATERAL-RATIO u150) ;; 150% minimum collateral ratio
(define-constant LIQUIDATION-THRESHOLD u130) ;; 130% liquidation threshold
(define-constant INTEREST-RATE-YEARLY u50) ;; 5.0% annual interest (scaled by 10)
(define-constant BLOCKS-PER-YEAR u52560) ;; ~10 minute blocks, 365 days
(define-constant INTEREST-RATE-PER-BLOCK (/ (* INTEREST-RATE-YEARLY u100000) (* BLOCKS-PER-YEAR u1000)))
(define-constant PROTOCOL-FEE-PERCENT u10) ;; 1.0% protocol fee from interest (scaled by 10)

;; Data Structures

;; User deposits tracking
(define-map user-deposits
  principal
  uint
)
(define-map total-deposits
  uint
  uint
) ;; [height, amount]
(define-map protocol-fees
  uint
  uint
) ;; [height, amount]

;; Loan tracking
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    loan-amount: uint,
    interest-accumulated: uint,
    creation-height: uint,
    last-interest-height: uint,
    status: (string-ascii 20),
  }
)

(define-map user-loans
  principal
  (list 20 uint)
)

;; Maps user to list of their loan IDs

;; State variables
(define-data-var loan-nonce uint u0)
(define-data-var total-collateral uint u0)
(define-data-var total-borrowed uint u0)
(define-data-var paused bool false)

;; Administrative Functions

(define-public (set-paused (paused-state bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set paused paused-state)
    (ok paused-state)
  )
)