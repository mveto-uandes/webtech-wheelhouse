**Can a bike have more than one repair open at the same time, or a repair cover more than one bike?**
The description always talks about one bike at a time, so I assumed one repair is always for exactly one bike, and a bike can have many repairs over time but not two open ones at once. If that's wrong, `repairs` would probably need something to stop two open repairs on the same bike, or the relationship would need to change to allow it on purpose.

**Who is actually allowed to approve or decline the quote?**
The owner says "we call the person... wait for them to say yes," which sounds like only the registered customer decides. I assumed that, so there's no field for anyone else authorizing a repair, like someone picking up a bike for a friend. If that's wrong, I'd probably need an `authorized_by` field somewhere, or a way to log who actually said yes if it wasn't the owner of the bike.

**Do photos need to be linked to which employee took them?**
The owner says photos are so nobody argues later about who made a scratch, which made me think accountability could matter, but never says photos are tied to a specific person. I assumed they don't need that, so `photos` only has `bike_id` and `taken_at`, no employee. If that's wrong, `photos` would need an `employee_id` column pointing at whoever took it.
