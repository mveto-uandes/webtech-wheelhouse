
1. As a customer, I want to describe the problem with my bike when I drop it off, so that the mechanic knows what to look at without me having to repeat myself later.
2. As staff, I want to log a new repair job with the customer's and bike's details when a bike is dropped off, so that there's a record of every bike currently in the shop.
3. As a mechanic, I want to record my diagnosis and the parts/labor needed, so that staff can generate an accurate quote for the customer.
4. As a customer, I want to see the estimated cost of a repair before work starts, so that I can decide whether to approve it.
5. As a customer, I want to approve or decline a proposed repair, so that the shop doesn't do (and charge for) work I didn't agree to.
6. As staff, I want to log a new repair job, so that every bike entering the shop is tracked from day one.
7. As a mechanic, I want to update a job's status as I work on it, so that staff and the customer know the bike's progress without asking me directly.
8. As staff, I want to close out a completed job, so that it's marked finished and moves out of the active queue.
9. As a customer, I want to know when my bike is ready for pickup, so that I don't make an unnecessary trip to the shop.
10. As staff, I want to record payment when a customer picks up their bike, so that the shop has an accurate record of revenue per job.
11. As a customer, I want to view the repair history of my bike, so that I can track what's been done to it over time.
12. As the shop owner, I want to see publicly available pricing for common repairs, so that customers have transparent expectations before they even bring a bike in.
13. As staff, I want to see all bikes currently in the shop and their status, so that I can answer customer questions without checking with the mechanic directly.

Story 6, 7, and 8 were split from a single broader story — "As staff, I want to manage repair jobs" — into three independently valuable pieces: logging a job, updating its status, and closing it out.

Acceptance criteria:

Story 2 — Log a new repair job

- Given a customer drops off a bike, staff can record customer name, contact info, bike description, and reported problem.
- Given a job is logged, it appears immediately in the shop's active job list with status "Received."
- Given required fields (customer contact, bike description) are missing, the job cannot be saved and staff sees which fields are missing.

Story 5 — Approve or decline a proposed repair

- Given a quote has been generated, the customer can approve or decline it.
- Given the customer approves, the job status changes to "Approved" and the mechanic is notified to proceed.
- Given the customer declines, the job status changes to "Declined" and no further work/charges occur on that job.

Story 7 — Update job status

- Given a mechanic is working a job, they can change its status (e.g. Received → Diagnosing → Approved → In Repair → Ready for Pickup).
- Given a status change is made, staff and the customer-facing view reflect the new status.
- Given an invalid transition is attempted (e.g. marking "Ready for Pickup" before a diagnosis exists), the system rejects it and explains why.

Story 13 — See all bikes currently in the shop

- Given jobs exist, the list shows bike, customer, and current status for each.
- Given a job's status changes, the list reflects the updated status.
- Given no jobs are currently active, the page shows a message such as "No bikes currently in the shop" instead of a blank list.
