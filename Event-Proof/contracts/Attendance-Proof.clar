;; Event Attendance Verification Protocol (EAVP) Smart Contract
;; A comprehensive blockchain-based system for managing event attendance verification
;; and automated reward distribution. This protocol enables event organizers to create
;; verifiable attendance records, allows participants to check in/out of events,
;; supports authorized verification of attendance, and distributes STX rewards based
;; on verified participation and engagement duration.

;; System Error Constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-REWARD-ALREADY-CLAIMED (err u101))
(define-constant ERR-EVENT-NOT-FINISHED (err u102))
(define-constant ERR-EVENT-EXPIRED (err u103))
(define-constant ERR-NO-REWARD-AVAILABLE (err u104))
(define-constant ERR-EVENT-NOT-FOUND (err u105))
(define-constant ERR-INSUFFICIENT-TREASURY-BALANCE (err u106))
(define-constant ERR-INVALID-DURATION-RANGE (err u107))
(define-constant ERR-DUPLICATE-EVENT-REGISTRATION (err u108))
(define-constant ERR-INVALID-START-TIME (err u110))
(define-constant ERR-INVALID-REWARD-CONFIGURATION (err u111))
(define-constant ERR-INVALID-MINIMUM-PARTICIPATION (err u112))
(define-constant ERR-EVENT-CURRENTLY-INACTIVE (err u120))
(define-constant ERR-MISSING-CHECK-IN-RECORD (err u121))
(define-constant ERR-ATTENDANCE-ALREADY-VERIFIED (err u122))
(define-constant ERR-INVALID-PARTICIPANT-ADDRESS (err u123))
(define-constant ERR-INVALID-PRINCIPAL-ADDRESS (err u1002))
(define-constant ERR-VERIFIER-ALREADY-AUTHORIZED (err u1003))
(define-constant ERR-VERIFIER-NOT-AUTHORIZED (err u1004))
(define-constant ERR-INVALID-DEPOSIT-AMOUNT (err u1005))
(define-constant ERR-EVENT-ALREADY-DEACTIVATED (err u1006))
(define-constant ERR-TRANSFER-OPERATION-FAILED (err u1007))

;; Validation and Limits Constants
(define-constant maximum-event-duration-blocks u52560)
(define-constant minimum-event-duration-blocks u144)
(define-constant maximum-reward-amount-limit u1000000000000)
(define-constant minimum-event-title-length u3)
(define-constant maximum-event-title-length u50)
(define-constant minimum-event-description-length u10)
(define-constant maximum-event-description-length u200)

;; Text Validation Error Constants
(define-constant ERR-INVALID-EVENT-TITLE (err u2000))
(define-constant ERR-INVALID-EVENT-DESCRIPTION (err u2001))
(define-constant ERR-INVALID-TEXT-FORMAT (err u2002))

;; System Configuration Constants
(define-constant burn-address-constant 'SP000000000000000000002Q6VF78)

;; Contract State Variables
(define-data-var system-administrator principal tx-sender)
(define-data-var global-event-counter uint u0)
(define-data-var treasury-balance uint u0)

;; Core Data Structures
(define-map event-information-registry 
    uint 
    {
        event-title: (string-ascii 50),
        event-description: (string-ascii 200),
        event-start-block: uint,
        event-end-block: uint,
        base-reward-amount: uint,
        bonus-reward-amount: uint,
        minimum-attendance-duration: uint,
        event-creator: principal,
        is-active: bool
    })

(define-map participant-attendance-records 
    { event-identifier: uint, participant-address: principal }
    {
        check-in-block-height: uint,
        check-out-block-height: uint,
        total-attendance-blocks: uint,
        verification-status: bool
    })

(define-map attendance-verification-details
    { event-identifier: uint, participant-address: principal }
    {
        verifying-authority: principal,
        verification-block-height: uint
    })

(define-map reward-claim-history
    { event-identifier: uint, participant-address: principal }
    {
        distributed-reward-amount: uint,
        claim-block-height: uint,
        reward-category: uint
    })

(define-map authorized-verification-agents principal bool)

;; Read-Only Information Functions
(define-read-only (get-system-administrator)
    (var-get system-administrator))

(define-read-only (get-event-information (event-identifier uint))
    (map-get? event-information-registry event-identifier))

(define-read-only (get-participant-attendance (event-identifier uint) (participant-address principal))
    (map-get? participant-attendance-records {event-identifier: event-identifier, participant-address: participant-address}))

(define-read-only (get-reward-claim-information (event-identifier uint) (participant-address principal))
    (map-get? reward-claim-history {event-identifier: event-identifier, participant-address: participant-address}))

(define-read-only (check-verifier-authorization (verification-agent principal))
    (default-to false (map-get? authorized-verification-agents verification-agent)))

(define-read-only (validate-event-existence (event-identifier uint))
    (is-some (map-get? event-information-registry event-identifier)))

(define-read-only (check-attendance-verification-eligibility (event-identifier uint) (participant-address principal))
    (let ((attendance-information (get-participant-attendance event-identifier participant-address))
          (event-information (get-event-information event-identifier)))
        (and 
            (is-some attendance-information)
            (is-some event-information)
            (get is-active (unwrap! event-information false))
            (> (get check-in-block-height (unwrap! attendance-information false)) u0)
            (not (get verification-status (unwrap! attendance-information false)))
        )))

(define-read-only (get-verification-details (event-identifier uint) (participant-address principal))
    (map-get? attendance-verification-details {event-identifier: event-identifier, participant-address: participant-address}))

(define-read-only (get-comprehensive-verification-status (event-identifier uint) (participant-address principal))
    (let ((attendance-information (get-participant-attendance event-identifier participant-address))
          (verification-information (get-verification-details event-identifier participant-address)))
        {
            is-verified: (match attendance-information
                        attendance-data (get verification-status attendance-data)
                        false),
            verification-details: verification-information
        }))

;; Private Text Validation Helper
(define-private (validate-text-format (text-content (string-ascii 200)))
    (let ((content-length (len text-content)))
        (and
            (> content-length u0)
            (not (is-eq (unwrap-panic (element-at text-content u0)) " "))
            (not (is-eq (unwrap-panic (element-at text-content (- content-length u1))) " ")))))

;; Event Creation and Management Functions
(define-public (create-new-event (event-title (string-ascii 50)) 
                                (event-description (string-ascii 200))
                                (start-block-height uint)
                                (duration-in-blocks uint)
                                (base-participation-reward uint)
                                (bonus-engagement-reward uint)
                                (minimum-participation-blocks uint))
    (let ((next-event-identifier (+ (var-get global-event-counter) u1))
          (calculated-end-block (+ start-block-height duration-in-blocks))
          (current-block-height block-height)
          (title-character-count (len event-title))
          (description-character-count (len event-description)))
        (begin
            (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)

            (asserts! (and (>= title-character-count minimum-event-title-length)
                          (<= title-character-count maximum-event-title-length)
                          (validate-text-format event-title))
                     ERR-INVALID-EVENT-TITLE)

            (asserts! (and (>= description-character-count minimum-event-description-length)
                          (<= description-character-count maximum-event-description-length)
                          (validate-text-format event-description))
                     ERR-INVALID-EVENT-DESCRIPTION)

            (asserts! (and (>= duration-in-blocks minimum-event-duration-blocks) 
                          (<= duration-in-blocks maximum-event-duration-blocks)) 
                     ERR-INVALID-DURATION-RANGE)

            (asserts! (> start-block-height current-block-height) 
                     ERR-INVALID-START-TIME)

            (asserts! (and (<= base-participation-reward maximum-reward-amount-limit)
                          (<= bonus-engagement-reward maximum-reward-amount-limit)
                          (> base-participation-reward u0))
                     ERR-INVALID-REWARD-CONFIGURATION)

            (asserts! (and (> minimum-participation-blocks u0)
                          (<= minimum-participation-blocks duration-in-blocks))
                     ERR-INVALID-MINIMUM-PARTICIPATION)

            (map-set event-information-registry next-event-identifier
                {
                    event-title: event-title,
                    event-description: event-description,
                    event-start-block: start-block-height,
                    event-end-block: calculated-end-block,
                    base-reward-amount: base-participation-reward,
                    bonus-reward-amount: bonus-engagement-reward,
                    minimum-attendance-duration: minimum-participation-blocks,
                    event-creator: tx-sender,
                    is-active: true
                })

            (var-set global-event-counter next-event-identifier)
            (ok next-event-identifier))))

(define-public (deactivate-existing-event (event-identifier uint))
    (let 
        (
            (event-information (unwrap! (get-event-information event-identifier) ERR-EVENT-NOT-FOUND))
        )
        (begin
            (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (get is-active event-information) ERR-EVENT-ALREADY-DEACTIVATED)
            (map-set event-information-registry event-identifier
                (merge event-information {is-active: false}))
            (ok true))))

;; Attendance Management Functions
(define-public (register-event-check-in (event-identifier uint))
    (let ((event-information (unwrap! (get-event-information event-identifier) ERR-EVENT-NOT-FOUND)))
        (begin
            (asserts! (get is-active event-information) ERR-EVENT-EXPIRED)
            (asserts! (>= block-height (get event-start-block event-information)) ERR-EVENT-NOT-FINISHED)
            (asserts! (< block-height (get event-end-block event-information)) ERR-EVENT-EXPIRED)
            (asserts! (is-none (get-participant-attendance event-identifier tx-sender)) ERR-DUPLICATE-EVENT-REGISTRATION)
            (map-set participant-attendance-records 
                {event-identifier: event-identifier, participant-address: tx-sender}
                {
                    check-in-block-height: block-height,
                    check-out-block-height: u0,
                    total-attendance-blocks: u0,
                    verification-status: false
                })
            (ok true))))

(define-public (register-event-check-out (event-identifier uint))
    (let ((attendance-information (unwrap! (get-participant-attendance event-identifier tx-sender) ERR-EVENT-NOT-FOUND))
          (event-information (unwrap! (get-event-information event-identifier) ERR-EVENT-NOT-FOUND)))
        (begin
            (asserts! (get is-active event-information) ERR-EVENT-EXPIRED)
            (asserts! (> block-height (get check-in-block-height attendance-information)) ERR-INVALID-DURATION-RANGE)
            (let ((calculated-attendance-duration (- block-height (get check-in-block-height attendance-information))))
                (map-set participant-attendance-records
                    {event-identifier: event-identifier, participant-address: tx-sender}
                    {
                        check-in-block-height: (get check-in-block-height attendance-information),
                        check-out-block-height: block-height,
                        total-attendance-blocks: calculated-attendance-duration,
                        verification-status: false
                    })
                (ok calculated-attendance-duration)))))

;; Attendance Verification Functions
(define-public (verify-participant-attendance (event-identifier uint) (participant-address principal))
    (let ((attendance-information (unwrap! (get-participant-attendance event-identifier participant-address) ERR-EVENT-NOT-FOUND))
          (event-information (unwrap! (get-event-information event-identifier) ERR-EVENT-NOT-FOUND)))
        (begin
            (asserts! (check-verifier-authorization tx-sender) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (get is-active event-information) ERR-EVENT-CURRENTLY-INACTIVE)
            (asserts! (not (is-eq participant-address tx-sender)) ERR-INVALID-PARTICIPANT-ADDRESS)
            (asserts! (not (get verification-status attendance-information)) ERR-ATTENDANCE-ALREADY-VERIFIED)
            (asserts! (> (get check-in-block-height attendance-information) u0) ERR-MISSING-CHECK-IN-RECORD)

            (map-set participant-attendance-records
                {event-identifier: event-identifier, participant-address: participant-address}
                (merge attendance-information {verification-status: true}))

            (map-set attendance-verification-details
                {event-identifier: event-identifier, participant-address: participant-address}
                {
                    verifying-authority: tx-sender,
                    verification-block-height: block-height
                })
            (ok true))))

;; Reward Distribution Functions
(define-public (claim-participation-reward (event-identifier uint))
    (let ((event-information (unwrap! (get-event-information event-identifier) ERR-EVENT-NOT-FOUND))
          (attendance-information (unwrap! (get-participant-attendance event-identifier tx-sender) ERR-EVENT-NOT-FOUND)))
        (begin
            (asserts! (> block-height (get event-end-block event-information)) ERR-EVENT-NOT-FINISHED)
            (asserts! (get verification-status attendance-information) ERR-UNAUTHORIZED-ACCESS)
            (asserts! (is-none (get-reward-claim-information event-identifier tx-sender)) ERR-REWARD-ALREADY-CLAIMED)

            (let ((base-reward-portion (get base-reward-amount event-information))
                  (bonus-reward-portion (if (>= (get total-attendance-blocks attendance-information)
                                              (get minimum-attendance-duration event-information))
                                          (get bonus-reward-amount event-information)
                                          u0))
                  (total-calculated-reward (+ base-reward-portion bonus-reward-portion)))

                (asserts! (<= total-calculated-reward (var-get treasury-balance)) ERR-INSUFFICIENT-TREASURY-BALANCE)
                (try! (as-contract (stx-transfer? total-calculated-reward tx-sender tx-sender)))
                (var-set treasury-balance (- (var-get treasury-balance) total-calculated-reward))

                (map-set reward-claim-history
                    {event-identifier: event-identifier, participant-address: tx-sender}
                    {
                        distributed-reward-amount: total-calculated-reward,
                        claim-block-height: block-height,
                        reward-category: (if (> bonus-reward-portion u0) u2 u1)
                    })
                (ok total-calculated-reward)))))

;; Verification Agent Management Functions
(define-public (authorize-verification-agent (agent-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (not (is-eq agent-address burn-address-constant)) ERR-INVALID-PRINCIPAL-ADDRESS)
        (asserts! (not (default-to false (map-get? authorized-verification-agents agent-address))) ERR-VERIFIER-ALREADY-AUTHORIZED)
        (map-set authorized-verification-agents agent-address true)
        (ok true)))

(define-public (revoke-verification-agent (agent-address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (not (is-eq agent-address burn-address-constant)) ERR-INVALID-PRINCIPAL-ADDRESS)
        (asserts! (default-to false (map-get? authorized-verification-agents agent-address)) ERR-VERIFIER-NOT-AUTHORIZED)
        (map-set authorized-verification-agents agent-address false)
        (ok true)))

;; Treasury Management Functions
(define-public (deposit-treasury-funds (deposit-amount uint))
    (begin
        (asserts! (> deposit-amount u0) ERR-INVALID-DEPOSIT-AMOUNT)
        (asserts! (<= deposit-amount (stx-get-balance tx-sender)) ERR-INVALID-DEPOSIT-AMOUNT)
        (let ((transfer-operation (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))))
            (begin
                (var-set treasury-balance (+ (var-get treasury-balance) deposit-amount))
                (ok true)))))

(define-public (withdraw-treasury-funds (withdrawal-amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (<= withdrawal-amount (var-get treasury-balance)) ERR-INSUFFICIENT-TREASURY-BALANCE)
        (try! (as-contract (stx-transfer? withdrawal-amount tx-sender tx-sender)))
        (var-set treasury-balance (- (var-get treasury-balance) withdrawal-amount))
        (ok true)))