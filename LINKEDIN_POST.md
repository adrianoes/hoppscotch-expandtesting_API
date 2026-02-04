🚀 Mastering Hoppscotch: Building Independent API Tests with Request Orchestration

Despite the superficial documentation on [sending requests](https://docs.hoppscotch.io/documentation/features/scripts#sending-requests) in pre and post scripts, I've partnered with GitHub Copilot to create a comprehensive solution that fully leverages Hoppscotch's capabilities.

**What We Built:**

📋 **Pre-Request Script Orchestration** - Automated environment preparation using fetch() to:
- Register test users dynamically
- Authenticate and capture tokens
- Create dependent resources (notes, etc.)
- Initialize all required variables

🧹 **Post-Request Script Cleanup** - Automated environment teardown to:
- Delete created resources
- Clear test data
- Unset environment variables
- Prevent test pollution between runs

**The Game-Changer: Test Execution Filters**

Because our tests are fully independent, we implemented smart filtering to run exactly what you need:

✅ Run a single test: `quick-test.ps1 TC001`
✅ Run all tests: `quick-test.ps1 all`
✅ Run only happy path: `quick-test.ps1 pos`
✅ Run only negative tests: `quick-test.ps1 neg`
✅ Advanced control: `run-tests.ps1 -TestCase TC001 -Delay 2000`
✅ Multiple tests: `run-tests.ps1 -Multiple TC001,TC010,TC020`
✅ Full filtering: `-Positive`, `-Negative`, custom delays

This approach transforms your API testing workflow from linear execution to intelligent, on-demand testing.

**Results:**
- 39 independent tests
- 98.8% pass rate
- 100% automated setup/teardown
- Zero test interdependencies

Interested in building bulletproof API tests with Hoppscotch? Check out the repository:

👉 https://github.com/adrianoes/hoppscotch-expandtesting_api

#Hoppscotch #APITesting #QA #Automation #TestingFramework #GitHub
