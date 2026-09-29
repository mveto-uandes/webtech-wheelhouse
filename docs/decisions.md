**Can a bike have more than one repair open at the same time, or a repair cover more than one bike?**
The description always talks about one bike at a time, so I assumed one repair is always for exactly one bike, and a bike can have many repairs over time but not two open ones at once. If that's wrong, `repairs` would probably need something to stop two open repairs on the same bike, or the relationship would need to change to allow it on purpose.

**Who is actually allowed to approve or decline the quote?**
The owner says "we call the person... wait for them to say yes," which sounds like only the registered customer decides. I assumed that, so there's no field for anyone else authorizing a repair, like someone picking up a bike for a friend. If that's wrong, I'd probably need an `authorized_by` field somewhere, or a way to log who actually said yes if it wasn't the owner of the bike.

**Do photos need to be linked to which employee took them?**
The owner says photos are so nobody argues later about who made a scratch, which made me think accountability could matter, but never says photos are tied to a specific person. I assumed they don't need that, so `photos` only has `bike_id` and `taken_at`, no employee. If that's wrong, `photos` would need an `employee_id` column pointing at whoever took it.

## Lab 7: what happens when something gets deleted

**Which `dependent:` option did each `has_many` get?**
- `Customer#bikes` and `Service#repair_line_items` are `restrict_with_error`, because the lab asks for it: a customer with bikes, or a service that was charged at least once, can't be deleted.
- `Bike#repairs` is also `restrict_with_error`. A bike's repair history is the shop's record of what was done and charged, so I didn't want deleting a bike to quietly wipe it.
- `Repair#payments` is `restrict_with_error` too. Money that was actually received shouldn't disappear because someone deleted the repair.
- `Repair#repair_line_items` is `destroy`. A line item makes no sense without its repair, so if a repair (with no payments) is deleted, its lines go with it.
- `Employee#repairs` is `nullify`. `mechanic_id` can already be null ("unassigned"), so if a mechanic leaves, their repairs stay and just become unassigned.
- The `through` associations (`Customer#repairs`, `Service#repairs`, `Repair#services`) repeat the option of the association they go through, so the two never disagree.

**How is "the customer's answer" recorded?**
There's no separate column for it, only `status`. What the customer says yes to is the quote, and the quote is the repair's line items. So a repair that is `in_repair`, `ready_for_pickup` or `completed` must have at least one line item, which is the approved work. A column like `approved_at` would be more explicit, but the lab doesn't allow new migrations.

**Which columns get cleaned up before saving?**
Bike serial numbers are stripped and upper-cased in a `before_validation` callback, so `" wtu123 "` and `"WTU123"` count as the same bike. Service names and customer names get their extra spaces squeezed out with `normalizes`, so `"Flat  tire repair "` can't sneak past the unique name on the price list. They aren't upper-cased, though, because they're shown to people as typed.

## Lab 8: writing from the browser

**How many empty service rows does the repair form offer, and how do you get more?**
The repair form always shows its current lines plus 3 empty rows. That covers most drop-offs: the usual repair in the seed has one or two services. The form has to work without JavaScript, so it can't grow by itself. If a repair needs more than 3 new services, you save it, press Edit, and you get 3 more empty rows. A row left on "No service" is ignored.

**Why are the line errors named after the service?**
On the repair's form there can be several lines, so "Charged price must be more than 0" doesn't tell you which one. The message says "Charged price for Flat tire repair must be more than 0", and the price field on that row is marked in red.

**Why are payments still read-only?**
The lab asks for full create/edit/delete on customers, bikes, repairs, services and staff. Payments aren't in that list, and the counter doesn't take payments in the app yet, so they keep their Lab 6 pages.

**Why is Turbo back?**
It was removed in Lab 4 to keep the route list short. The Delete button asks for confirmation with `data-turbo-confirm`, which is what Rails provides for that, so `turbo-rails` is back in the Gemfile and the import map.
