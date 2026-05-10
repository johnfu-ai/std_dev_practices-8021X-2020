# Quick Reference: Empirical Development Practices

**Purpose**: Fast reference for developers to replace speculation with proof  
**Phase**: 05-Implementation (but applies throughout lifecycle)  
**Core Principle**: **PROVE IT** before you ship it

## 🚦 The Three Sacred Rules

### 1. RED: Write Failing Test First
```typescript
// ❌ WRONG - Code without test
export class User {
  changeEmail(email: string) { /*...*/ }
}

// ✅ RIGHT - Test first
describe('User.changeEmail', () => {
  it('should update email address', () => {
    const user = User.create(Email.from('old@example.com'));
    user.changeEmail(Email.from('new@example.com'));
    expect(user.getEmail().getValue()).toBe('new@example.com');
  });
});
// NOW implement changeEmail()
```

### 2. GREEN: Make Test Pass Quickly
```typescript
// Make it work first (commit sins if needed)
changeEmail(email: Email): void {
  this.email = email; // Simple, but works
}
```

### 3. REFACTOR: Clean Up While Tests Stay Green
```typescript
// Now make it clean
changeEmail(newEmail: Email): void {
  this.assertActive(); // Add preconditions
  const oldEmail = this.email;
  this.email = newEmail;
  this.publishEvent(new EmailChanged(this.id, oldEmail, newEmail));
}
```

## ⏱️ Speed Targets

| Activity | Target Time | Red Flag |
|----------|-------------|----------|
| Write test | 2-3 minutes | >5 minutes: test too complex |
| Make test pass | 3-5 minutes | >10 minutes: implementation too large |
| Refactor | 1-2 minutes | >5 minutes: design needs rethinking |
| **Full cycle** | **<10 minutes** | **>15 minutes: break it down** |

## 🔬 When to Use Spike Solutions

**Use spike when**: You don't know if something is feasible

```bash
# Example: Can we integrate with legacy API?
git checkout -b spike/legacy-api-poc
# Set timer for 4 hours max
# Try integration, document findings
# DELETE spike branch
git checkout main
git branch -D spike/legacy-api-poc
# Implement properly with TDD using knowledge gained
```

**Spike deliverable**: Written findings, NOT production code

## 🚶 Walking Skeleton Checklist

Before building features, prove architecture works end-to-end:

```markdown
- [ ] Database connection works
- [ ] API endpoint responds
- [ ] Frontend renders
- [ ] CI/CD pipeline builds and deploys
- [ ] Health check returns 200 OK
- [ ] Logging/monitoring configured
```

**Time**: 1-2 days  
**Value**: Proves choices work before investing months

## 🎯 YAGNI Decision Tree

```
Do we need this feature RIGHT NOW?
├─ YES → Is there a failing test that requires it?
│   ├─ YES → Implement it ✅
│   └─ NO → Write the test first 🔴
└─ NO → Will we definitely need it in next sprint?
    ├─ YES → Wait until next sprint (YAGNI) ⏸️
    └─ NO → Don't build it 🚫
```

## 📝 Assertion Checklist

Add assertions for:

```typescript
// ✅ Preconditions (what must be true before)
private assertPositiveAmount(amount: Money): void {
  if (amount.isNegativeOrZero()) {
    throw new InvalidOperationError('Amount must be positive');
  }
}

// ✅ Invariants (what must always be true)
private assertBalanceIntegrity(): void {
  if (!this.balance.equals(this.calculateFromTransactions())) {
    throw new InvariantViolationError('Balance mismatch');
  }
}

// ✅ Postconditions (what must be true after)
private assertAccountDebited(originalBalance: Money, amount: Money): void {
  if (!this.balance.equals(originalBalance.subtract(amount))) {
    throw new PostconditionViolationError('Debit failed');
  }
}
```

## 🔴 Red Flags: You're Speculating If...

| Statement | Problem | Solution |
|-----------|---------|----------|
| "I'm pretty sure this works" | Untested assumption | Write a test to prove it |
| "We'll need this later" | Gold-plating | YAGNI - wait for actual need |
| "This is too simple to test" | Famous last words | Especially test simple things |
| "Let me finish, then test" | Wrong order | Test FIRST (Red-Green-Refactor) |
| "The docs say it works" | Trust without verify | Docs lie; tests don't |
| "I've done this before" | Different context | Prove it works HERE |

## 🔄 Feedback Loop Quick Checks

### ✅ Healthy Signs
- [ ] Tests run in <5 seconds
- [ ] Red-Green-Refactor cycle <10 minutes
- [ ] Commit every 15-30 minutes
- [ ] CI green within 5 minutes
- [ ] Customer demos weekly
- [ ] No branches older than 2 days

### ❌ Warning Signs
- [ ] Tests take >30 seconds to run
- [ ] Haven't committed in >2 hours
- [ ] CI build broken >10 minutes
- [ ] Haven't shown customer progress in >1 week
- [ ] Branch open >3 days
- [ ] Writing code without running tests

## 📊 Daily Development Checklist

**Morning** (Start of Day):
```bash
- [ ] Pull latest code: git pull origin main
- [ ] Run full test suite: npm test
- [ ] Check CI status (all green?)
- [ ] Review failed builds from overnight
```

**During Development** (Every 10-30 minutes):
```bash
- [ ] Red: Write failing test
- [ ] Green: Make test pass
- [ ] Refactor: Clean up
- [ ] Run tests: npm test
- [ ] Commit: git commit -am "feat: ..."
```

**Before Lunch/End of Day**:
```bash
- [ ] All tests passing locally
- [ ] All changes committed
- [ ] Push to trigger CI: git push
- [ ] CI build green
- [ ] No compiler warnings
```

## 🎓 Learning Resources

| Topic | Document | Key Takeaway |
|-------|----------|--------------|
| **Full TDD Guide** | `docs/tdd-empirical-proof.md` | Complete empirical validation practices |
| **XP Practices** | `docs/xp-practices.md` | All 12 XP practices with examples |
| **DDD Integration** | `docs/ddd-implementation-guide.md` | Domain-focused testing |
| **Phase 05 Guide** | `ai/instructions/phase-05-implementation.instructions.md` | Implementation standards |

## 💡 Quick Wins for Tomorrow

1. **Measure your Red-Green-Refactor cycle**: Use a timer - aim for <10 minutes
2. **Add one assertion**: Pick one method, add precondition check with test
3. **Delete speculative code**: Find one "might need later" feature - remove it
4. **Run spike**: Pick one unknown - time-box 2 hours to prove/disprove
5. **Schedule customer demo**: Book 30 minutes to show this week's progress

## 🚀 Remember

> **"I'm pretty sure this will work"** = ❌ Speculation  
> **"Here's a passing test that proves it works"** = ✅ Empirical Proof

**When in doubt, write a test!** 🧪

---

**Full documentation**: See `docs/tdd-empirical-proof.md` for comprehensive guidance