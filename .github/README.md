# 🚀 GitHub Actions CI/CD Pipeline

This directory contains the GitHub Actions workflows for OMOMoney iOS app. The pipeline ensures code quality, runs tests, and provides automated feedback.

## 📋 **Workflows Overview**

### 1. **iOS CI/CD** (`ios.yml`)
**Triggers:** Push to `main`/`develop`, Pull Requests
**Purpose:** Full CI/CD pipeline with comprehensive testing

**Jobs:**
- 🏗️ **Build & Test**: Compiles app and runs unit tests
- 🧪 **UI Tests**: Executes UI automation tests
- ⚡ **Performance Tests**: Runs performance benchmarks
- 📏 **Code Quality**: SwiftLint and code style checks
- 🔒 **Security Scan**: Vulnerability scanning with Trivy
- 📦 **Build Archive**: Creates release archives (main branch only)
- 📢 **Notifications**: Provides status updates and PR comments

### 2. **Pull Request Checks** (`pr-checks.yml`)
**Triggers:** Pull Request events only
**Purpose:** Fast feedback for developers

**Jobs:**
- ⚡ **Quick Build**: Fast compilation check
- 🧪 **Unit Tests**: Core functionality tests
- 📏 **Code Quality**: SwiftLint and security checks
- 📦 **Dependency Check**: Vulnerability and license checks
- 📋 **PR Summary**: Automated PR status comment

## 🛠️ **Setup Requirements**

### **Repository Secrets**
```bash
# Required for Codecov integration
CODECOV_TOKEN=your_codecov_token_here

# Optional: For notifications to Slack/Discord
SLACK_WEBHOOK_URL=your_slack_webhook_url
DISCORD_WEBHOOK_URL=your_discord_webhook_url
```

### **Branch Protection Rules**
Enable these in GitHub repository settings:

1. **Require status checks to pass before merging**
   - ✅ `build-and-test`
   - ✅ `unit-tests`
   - ✅ `code-quality`

2. **Require branches to be up to date before merging**

3. **Dismiss stale PR approvals when new commits are pushed**

## 📊 **Code Coverage**

### **Targets by Module**
- **Services**: 90% (Core business logic)
- **ViewModels**: 80% (UI state management)
- **Views**: 75% (UI components)
- **Overall**: 85% (Project-wide)

### **Coverage Reports**
- Generated automatically on every test run
- Uploaded to Codecov for historical tracking
- Available as artifacts in GitHub Actions
- Integrated with PR status checks

## 🔧 **Local Development**

### **Running Tests Locally**
```bash
# Run all tests
xcodebuild test -project OMOMoney.xcodeproj -scheme OMOMoney -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.5'

# Run specific test target
xcodebuild test -project OMOMoney.xcodeproj -scheme OMOMoney -only-testing:OMOMoneyTests -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.5'

# Run with coverage
xcodebuild test -project OMOMoney.xcodeproj -scheme OMOMoney -enableCodeCoverage YES -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.5'
```

### **SwiftLint Local Usage**
```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint lint

# Auto-fix issues
swiftlint lint --fix
```

### **Code Coverage Local Generation**
```bash
# Generate coverage report
xcrun xccov view --report --json path/to/TestResults.xcresult > coverage.json

# View coverage in terminal
xcrun xccov view --report path/to/TestResults.xcresult
```

## 📈 **Performance Monitoring**

### **Test Execution Times**
- **Unit Tests**: Target < 20 seconds
- **UI Tests**: Target < 60 seconds
- **Full Pipeline**: Target < 10 minutes

### **Resource Usage**
- **Memory**: < 4GB per job
- **Storage**: < 10GB cache per run
- **CPU**: Optimized for parallel execution

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Build Failures**
   ```bash
   # Check Xcode version compatibility
   xcodebuild -version
   
   # Clean derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

2. **Test Failures**
   ```bash
   # Run tests with verbose output
   xcodebuild test -project OMOMoney.xcodeproj -scheme OMOMoney -destination 'platform=iOS Simulator,name=iPhone 15,OS=18.5' -verbose
   ```

3. **SwiftLint Issues**
   ```bash
   # Check configuration
   swiftlint rules
   
   # Run with debug output
   swiftlint lint --debug
   ```

### **Cache Issues**
```bash
# Clear GitHub Actions cache
# This requires manual intervention in the Actions tab
# Or push a commit with [skip cache] in the message
```

## 🔄 **Workflow Customization**

### **Adding New Jobs**
1. Define job in appropriate workflow file
2. Set dependencies with `needs:`
3. Configure timeout and resource limits
4. Add to notification system

### **Modifying Test Targets**
1. Update `-only-testing:` parameters
2. Adjust coverage exclusions in `codecov.yml`
3. Update SwiftLint exclusions in `.swiftlint.yml`

### **Adding New Platforms**
1. Update `runs-on` matrix
2. Add platform-specific build commands
3. Configure platform-specific test destinations

## 📚 **Best Practices**

### **For Developers**
- ✅ Write tests for new features
- ✅ Maintain code coverage above thresholds
- ✅ Follow SwiftLint rules
- ✅ Use meaningful commit messages
- ✅ Create small, focused PRs

### **For Reviewers**
- ✅ Check CI/CD status before merging
- ✅ Review code coverage reports
- ✅ Verify test quality
- ✅ Check for security issues
- ✅ Ensure performance benchmarks pass

### **For Maintainers**
- ✅ Monitor pipeline performance
- ✅ Update dependencies regularly
- ✅ Review and update thresholds
- ✅ Monitor security scan results
- ✅ Optimize workflow efficiency

## 🔗 **Integration Points**

### **External Services**
- **Codecov**: Code coverage reporting
- **SwiftLint**: Code quality enforcement
- **Trivy**: Security vulnerability scanning
- **GitHub**: Status checks and PR integration

### **Notifications**
- **PR Comments**: Automated status updates
- **Status Checks**: GitHub branch protection
- **Artifacts**: Test results and coverage reports
- **Security**: Vulnerability alerts

## 📞 **Support**

### **Getting Help**
1. Check workflow logs in GitHub Actions
2. Review troubleshooting section above
3. Check GitHub Issues for known problems
4. Contact maintainers for complex issues

### **Contributing**
1. Fork the repository
2. Create feature branch
3. Make changes and add tests
4. Ensure CI/CD passes
5. Submit pull request

---

**Last Updated:** $(date)
**Pipeline Version:** 1.0.0
**Maintainer:** OMOMoney Team
