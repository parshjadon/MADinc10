# TrailMates — Flutter Signup Form Quest

**Course:** MAD 4360, Activity 10  
**Student:** Parsh Jadon  
**Track:** Graduate — Task A + Task C only  
**Format:** Solo; no partner or group contributions  
**Due:** October 27, 2026, 8:30 PM course local time

TrailMates is a hiking-themed signup demo with a forest-green Material theme. Required name/email/password validation and exact password confirmation precede a green success SnackBar and a personalized welcome screen. No account is created, authenticated, or stored. Task B is not implemented.

## Authorship and solo contribution

This is Parsh Jadon's individual submission. The implementation and documentation were prepared with coding-assistant support, and Parsh Jadon has confirmed reviewing and verifying the completed work.

Solo project scope: form, theme, local tip feature, Task C confirmation and navigation, tests, evidence renders, and documentation. There are no partner contributions. The reflection and explanation of the implementation belong to this individual submission.

## Design record and privacy boundary

```text
Get a signup tip
  -> clear prior result/error; disable controls; show 500 ms local loading
  -> LocalTipSource.select(selected local test scenario)
  -> fixed category password_help -> first bundled tip
  -> plain-text result OR error + Retry
Retry -> reset scenario to normal -> loading -> bundled tip

Sign Up -> FormState.validate() -> every validator must pass
  -> clear password controllers -> green SnackBar -> WelcomePage(trimmedName)
```

`lib/signup_tip.dart` stores three fixed tips. Selection always returns the first tip for `password_help`; it is deterministic and does not personalize results. All tips are under 240 characters, and the selected tip is checked for blank/overlength content. Results use `Text`, with the label **“Preset demo tip—not live AI.”**

`LocalTipSource` accepts only `TipScenario`, never a name, email, password, controller, or form object. `SignupTipCard` receives no form data and cannot approve signup. There are no HTTP calls, live AI services, servers, API keys, analytics, or persistence calls. The main release manifest requests no Internet permission; Flutter's debug tooling uses separate platform configuration.

The test selector exposes normal data, simulated failure, an empty tip list, and missing category data. Empty/missing collections are checked before indexing. Retry restores the normal bundled-data scenario explicitly; it does not repair an external service. A `mounted` check prevents asynchronous updates after disposal.

## Flutter concepts in this implementation

`MyApp` and `WelcomePage` are stateless because their output follows their configuration. `SignupPage` owns persistent form/controller state; `SignupTipCard` uses `setState` for loading, result, error, and selected scenario. The persistent `GlobalKey<FormState>` lets the submit handler run all validators using `validate()`: an error string blocks submission, and `null` passes a field. All four controllers are disposed when the page is disposed.

Names are trimmed and cannot be whitespace-only. Email uses a simple local `name@domain.suffix` pattern; it does not establish deliverability. Passwords require six characters for the classroom demo, and confirmation must match exactly, including case. `Navigator.push` with `MaterialPageRoute<void>` passes only the trimmed name to the welcome screen; password fields are cleared after successful validation.

```text
MyApp → MaterialApp (theme/navigation) → SignupPage → Scaffold
  ├── AppBar
  └── Center → ConstrainedBox → SingleChildScrollView → Column
      ├── Heading
      ├── Form (GlobalKey<FormState>)
      │   └── Column → four TextFormFields + Sign Up
      └── SignupTipCard → Card → scenario/action/status/retry
```

## Graduate reflection — Parsh Jadon

The following three graduate reflection responses connect the submitted implementation to its privacy boundaries, evaluation, and error handling.

### 1. Identify one privacy boundary in the local tip feature. What information does it keep out of the feature, and why?

The privacy boundary is the interface between the signup form and `LocalTipSource`, whose only input is a local test scenario. The tip feature receives no name, email, password, confirmation value, or form controller, so its output cannot depend on personal information. The full-form widget test requests a tip while the fields are empty and then verifies that submission still fails, demonstrating that tip generation and validation are independent. Restricting this interface reduces unnecessary data access and makes the boundary easier to inspect than a design that passes the entire form into a helper.

### 2. How would you evaluate whether the preset tips are useful, safe, and consistent? Name a small test set and at least one failure metric.

A small evaluation set would include all three bundled tips, repeated requests for the fixed category, simulated failure, an empty collection, and a missing category. Automated checks already verify deterministic selection, the bundled tips' nonempty length limit, and error/retry recovery; a content review should additionally reject advice that requests credentials, promises security, or implies signup approval. A failure metric would be the proportion of scenarios that crash, show an empty or overlength result, or leave the user unable to recover, with a target of zero in this small set. Usefulness should be evaluated separately by asking a few users to identify a concrete action from each tip, because passing software tests does not establish that the advice is understandable or helpful.

### 3. What should the UI do when local tip data is empty or missing? Explain your error and retry behavior.

When a collection is empty or missing, the UI should replace loading with an understandable message and a visible Retry action rather than displaying blank content or indexing a nonexistent item. `LocalTipSource.select` throws a typed `TipFailure` for both cases, and the card clears any earlier result before each request so stale success text cannot hide the failure. Retry resets the selected scenario to the normal bundled data, shows the brief local loading state again, and then displays the preset tip. Separate automated widget tests cover both empty and missing data and verify that the error disappears and the bundled result appears after retry.

### Trade-off and improvement

Always choosing the first tip makes behavior predictable and easy to test, but offers little variety. A practical improvement is a deterministic local rotation through reviewed tips using an index, without reading form values. That improvement would require sequence, wraparound, and invalid-entry tests. The current retry recovery restores known bundled data for a deliberate demo failure; it is not general recovery from corrupt app assets.

## Testing and observed results

Automated checks were executed with coding-assistant support on October 27, 2026, using Flutter 3.47.2 and Dart 3.13.2 on Windows. Parsh Jadon subsequently confirmed completing the remaining verification of the assignment, including the Android device and offline checks.

| Case | Input/action | Observed result |
| --- | --- | --- |
| Required fields | Four empty fields | Four errors; no welcome route |
| Invalid input | Whitespace name, `hiker@`, password `12345` | Name/email/password errors; blocked |
| Task C mismatch | `abcdef` vs. `ABCDEF` | Exact-match error; blocked |
| Task C success | `  Alex Trail  `, `alex@example.com`, matching `abcdef` | `Welcome, Alex Trail!` and green SnackBar |
| Password lifecycle | Return from welcome | Password field empty |
| Tip independence | Get tip with empty form, then submit | Tip succeeds; signup still blocked |
| Loading | Request tip | Progress indicator; tip action disabled |
| Consistency/length | Repeated selection; check all bundled tips | Same selected text; each tip 1–240 characters |
| Local error | Simulated error, then Retry | Error followed by bundled tip |
| Empty/missing data | Each scenario, then Retry | Error followed by bundled tip in both cases |
| Disposal | Remove tip widget during delay | No framework exception |

`flutter analyze`: **No issues found**. `flutter test --reporter expanded`: **8 tests passed**. The separate evidence-rendering test also passed.

```powershell
flutter pub get
flutter analyze
flutter test --reporter expanded
flutter test tool/evidence_test.dart --update-goldens --reporter expanded
flutter build apk --release
flutter devices
flutter run -d <your-android-device-id>
```

To reproduce the manual checks, use the table's validation inputs, test every local tip scenario and Retry, and repeat the tip cases on Android with airplane mode enabled. Device and offline verification are student-confirmed; the automated results above are recorded separately. Email syntax and the six-character classroom minimum are not production authentication controls.

## Implementation evidence

These are actual Flutter widget renders at 440 × 1280 with SDK fonts, not emulator screenshots. Regenerate them with the evidence command above.

1. [Signup screen](evidence/01-signup.png)
2. [Required validation](evidence/02-required-validation.png)
3. [Tip loading](evidence/03-tip-loading.png)
4. [Tip success](evidence/04-tip-success.png)
5. [Empty-data error](evidence/05-empty-tip-error.png)
6. [Successful retry](evidence/06-tip-retry-success.png)
7. [Password mismatch](evidence/07-password-mismatch.png)
8. [Personalized success](evidence/08-personalized-success.png)

## APK and submission

Build artifact: `build/app/outputs/flutter-apk/app-release.apk`. The release variant uses Flutter's default debug signing key for this classroom installable demo, not production release signing. Build outputs and machine-specific SDK paths are excluded from Git. The delivery folder beside this project contains the APK and source ZIP.

Repository: [parshjadon/MADinc10](https://github.com/parshjadon/MADinc10). Submission artifacts are the repository URL and the separately provided `TrailMates-release.apk`. This README includes the solo graduate track, Task A + Task C implementation, three reflection responses, testing results, and linked implementation evidence. Parsh Jadon has confirmed completing verification for submission.
