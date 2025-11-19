;; stackbounty.clar
;; A decentralized bounty board for the Stacks blockchain

;; --------------------------------
;; ERRORS
;; --------------------------------
(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_NOT_POSTER u101)
(define-constant ERR_ALREADY_SUBMITTED u102)
(define-constant ERR_BOUNTY_NOT_FOUND u103)
(define-constant ERR_EXPIRED u104)
(define-constant ERR_INVALID_AMOUNT u105)
(define-constant ERR_ALREADY_APPROVED u106)
(define-constant ERR_NOT_SUBMITTER u107)
(define-constant ERR_NO_REWARD u108)
(define-constant ERR_UNAUTHORIZED u109)

;; --------------------------------
;; STORAGE
;; --------------------------------
(define-data-var next-bounty-id uint u0)
(define-data-var owner principal tx-sender)
(define-data-var total-bounties uint u0)
(define-data-var total-developers uint u0)

(define-map bounties
  uint
  (tuple
    (poster principal)
    (title (string-ascii 64))
    (description (string-ascii 256))
    (category (string-ascii 32))
    (reward uint)
    (deadline uint)
    (status (string-ascii 32)) ;; open / submitted / approved / refunded
    (winner (optional principal))
  )
)

(define-map submissions
  (tuple (bounty-id uint) (developer principal))
  (tuple (submission (string-ascii 256)) (approved bool))
)

(define-map reputation
  principal
  (tuple (points uint) (completed uint))
)

;; --------------------------------
;; EVENTS (Not directly supported in Clarity)
;; --------------------------------
;; Events are emitted through print statements or can be tracked via contract interactions

;; --------------------------------
;; PUBLIC FUNCTIONS
;; --------------------------------

;; 1. Post a new bounty
(define-public (post-bounty (title (string-ascii 64)) (description (string-ascii 256)) (category (string-ascii 32)) (reward uint) (duration uint))
  (if (> reward u0)
      (let ((id (+ (var-get next-bounty-id) u1)))
        (try! (stx-transfer? reward tx-sender (as-contract tx-sender)))
        (map-set bounties id
          (tuple
            (poster tx-sender)
            (title title)
            (description description)
            (category category)
            (reward reward)
            (deadline (+ burn-block-height duration))
            (status "open")
            (winner none)))
        (var-set next-bounty-id id)
        (var-set total-bounties (+ (var-get total-bounties) u1))
        (ok (tuple (bounty-id id) (reward reward))))
      (err ERR_INVALID_AMOUNT))
)

;; 2. Submit a solution for a bounty
(define-public (submit-solution (bounty-id uint) (submission (string-ascii 256)))
  (match (map-get? bounties bounty-id)
    bounty
      (if (and (is-eq (get status bounty) "open") (<= burn-block-height (get deadline bounty)))
          (match (map-get? submissions (tuple (bounty-id bounty-id) (developer tx-sender)))
            existing (err ERR_ALREADY_SUBMITTED)
            (begin
              (map-set submissions (tuple (bounty-id bounty-id) (developer tx-sender))
                (tuple (submission submission) (approved false)))
              (ok "Submission received")))
          (err ERR_EXPIRED))
    (err ERR_BOUNTY_NOT_FOUND))
)

;; 3. Approve a submission and pay reward
(define-public (approve-solution (bounty-id uint) (developer principal))
  (match (map-get? bounties bounty-id)
    bounty
      (if (is-eq tx-sender (get poster bounty))
          (if (is-eq (get status bounty) "open")
              (match (map-get? submissions (tuple (bounty-id bounty-id) (developer developer)))
                s
                  (begin
                    (try! (stx-transfer? (get reward bounty) (as-contract tx-sender) developer))
                    (map-set submissions (tuple (bounty-id bounty-id) (developer developer))
                      (tuple (submission (get submission s)) (approved true)))
                    (map-set bounties bounty-id
                      (tuple
                        (poster (get poster bounty))
                        (title (get title bounty))
                        (description (get description bounty))
                        (category (get category bounty))
                        (reward (get reward bounty))
                        (deadline (get deadline bounty))
                        (status "approved")
                        (winner (some developer))))
                    (ok "Bounty paid"))
                (err ERR_NOT_SUBMITTER))
              (err ERR_ALREADY_APPROVED))
          (err ERR_NOT_POSTER))
    (err ERR_BOUNTY_NOT_FOUND))
)

;; 4. Refund a bounty if expired
(define-public (refund-bounty (bounty-id uint))
  (match (map-get? bounties bounty-id)
    bounty
      (if (and (is-eq tx-sender (get poster bounty)) (>= burn-block-height (get deadline bounty)) (is-eq (get status bounty) "open"))
          (begin
            (try! (stx-transfer? (get reward bounty) (as-contract tx-sender) tx-sender))
            (map-set bounties bounty-id
              (tuple
                (poster (get poster bounty))
                (title (get title bounty))
                (description (get description bounty))
                (category (get category bounty))
                (reward (get reward bounty))
                (deadline (get deadline bounty))
                (status "refunded")
                (winner none)))
            (ok "Bounty refunded"))
          (err ERR_EXPIRED))
    (err ERR_BOUNTY_NOT_FOUND))
)

;; 5. Rate a developer (1-5 points)
(define-public (rate-developer (developer principal) (points uint))
  (if (and (>= points u1) (<= points u5))
      (match (map-get? reputation developer)
        rep
          (begin
            (map-set reputation developer
              (tuple
                (points (+ (get points rep) points))
                (completed (+ (get completed rep) u1))))
            (ok "Reputation updated"))
        (begin
          (map-set reputation developer (tuple (points points) (completed u1)))
          (ok "New reputation added")))
      (err ERR_INVALID_AMOUNT))
)

;; 6. Admin - remove bounty (if fraudulent)
(define-public (remove-bounty (bounty-id uint))
  (if (is-eq tx-sender (var-get owner))
      (begin
        (map-delete bounties bounty-id)
        (ok "Bounty removed by admin"))
      (err ERR_UNAUTHORIZED))
)

;; --------------------------------
;; READ-ONLY FUNCTIONS
;; --------------------------------
(define-read-only (get-bounty (id uint))
  (map-get? bounties id)
)

(define-read-only (get-submission (bounty-id uint) (developer principal))
  (map-get? submissions (tuple (bounty-id bounty-id) (developer developer)))
)

(define-read-only (get-reputation (developer principal))
  (map-get? reputation developer)
)

(define-read-only (get-total-bounties)
  (var-get total-bounties)
)
