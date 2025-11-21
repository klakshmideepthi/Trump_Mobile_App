# Mobile App - Complete Technical Documentation

## Table of Contents

1. [App Overview](#app-overview)
2. [Architecture & Design Patterns](#architecture--design-patterns)
3. [App Entry Point & Initialization](#app-entry-point--initialization)
4. [Navigation System](#navigation-system)
5. [File Structure & Organization](#file-structure--organization)
6. [Data Models & View Models](#data-models--view-models)
7. [Firebase Integration](#firebase-integration)
8. [User Flows & Navigation Paths](#user-flows--navigation-paths)
9. [Detailed Component Documentation](#detailed-component-documentation)
10. [State Management](#state-management)
11. [API Integration](#api-integration)
12. [UI Components & Styling](#ui-components--styling)
13. [Utility Classes & Helpers](#utility-classes--helpers)

---

## App Overview

This is a comprehensive iOS mobile application built with **SwiftUI** that enables users to order mobile phone plans and SIM cards. The app provides a complete end-to-end ordering experience from account creation to order completion.

### Key Features

- **Multi-Provider Authentication**: Email/Password, Google Sign-In, Apple Sign-In
- **Plan Selection**: Dynamic plan loading based on ZIP code via VCare API
- **6-Step Order Flow**: Structured ordering process with progress tracking
- **Order Management**: Resume incomplete orders, view order history
- **Device Compatibility**: IMEI checking and device compatibility verification
- **SIM Selection**: Physical SIM or eSIM support
- **Number Porting**: Transfer existing phone numbers
- **Location Services**: Automatic address autofill using device location
- **Firebase Backend**: Complete Firebase integration (Auth, Firestore, Analytics)

### Technology Stack

- **Framework**: SwiftUI
- **Language**: Swift
- **Backend**: Firebase (Authentication, Firestore, Analytics, In-App Messaging)
- **State Management**: ObservableObject, @Published, @StateObject, @EnvironmentObject
- **Navigation**: NavigationStack with custom NavigationState
- **API Integration**: VCare API for plan data
- **Location Services**: CoreLocation for address autofill

---

## Architecture & Design Patterns

### MVVM (Model-View-ViewModel) Pattern

The app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Models**: Data structures (`OrderModels.swift`, `PhoneModels.swift`)
- **Views**: SwiftUI views (all `.swift` files in `Home/`, `OrderFlow/`, `Profile/`)
- **ViewModels**: `UserRegistrationViewModel`, `ContactInfoDetailViewModel`, `NavigationState`

### State Management Strategy

1. **Local State**: `@State` for view-specific state
2. **Shared State**: `@StateObject` for view model instances
3. **Global State**: `@EnvironmentObject` for app-wide state (NavigationState, ViewModels)
4. **Observable Objects**: `@Published` properties for reactive updates

### Dependency Injection

- ViewModels and managers are injected via `@EnvironmentObject` or `@ObservedObject`
- Singleton pattern for managers (`FirebaseManager.shared`, `FirebaseOrderManager.shared`)
- Shared instances for utilities (`NotificationManager.shared`, `LocationManager`)

---

## App Entry Point & Initialization

### MobileApp.swift

**Location**: `/MobileApp/MobileApp/MobileApp.swift`

**Purpose**: Main app entry point and initialization

#### AppDelegate Class

```swift
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, 
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 1. Configure Firebase
    FirebaseApp.configure()
    
    // 2. Initialize auth state manager
    _ = AuthStateManager.shared
    
    // 3. Enable debug mode for faster FIAM testing
    UserDefaults.standard.set(true, forKey: "FIRAnalyticsDebugEnabled")
    
    return true
  }
}
```

**Responsibilities**:
- Configures Firebase on app launch
- Initializes `AuthStateManager` singleton
- Enables Firebase Analytics debug mode
- Firebase Auth persistence is enabled by default

#### MobileApp Struct

```swift
@main
struct MobileApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  
  @StateObject private var navigationState = NavigationState()
  @StateObject private var userRegistrationViewModel = UserRegistrationViewModel()
  @StateObject private var contactInfoDetailViewModel = ContactInfoDetailViewModel()
  
  var body: some Scene {
    WindowGroup {
      NavigationStack {
        SplashView()
      }
      .environmentObject(navigationState)
      .environmentObject(userRegistrationViewModel)
      .environmentObject(contactInfoDetailViewModel)
    }
  }
}
```

**Key Points**:
- `@main` attribute marks this as the app entry point
- `@UIApplicationDelegateAdaptor` connects AppDelegate
- Creates three `@StateObject` instances for global state
- Wraps content in `NavigationStack` for navigation
- Starts with `SplashView()` as the initial view
- Injects environment objects for app-wide access

**Flow**: App Launch → AppDelegate → MobileApp → SplashView

---

## Navigation System

### NavigationState.swift

**Location**: `/MobileApp/MobileApp/NavigationState.swift`

**Purpose**: Centralized navigation state management

#### Class Structure

```swift
class NavigationState: ObservableObject {
  enum Destination: CustomStringConvertible {
    case splash
    case login
    case startNewOrder
    case orderFlow
    case orderDetails
    case home
  }
  
  @Published var showSplash: Bool = false
  @Published var showPreviousOrders: Bool = false
  @Published var showContactInfoDetail: Bool = false
  @Published var showInternationalLongDistance: Bool = false
  @Published var showPrivacyPolicy: Bool = false
  @Published var showTermsAndConditions: Bool = false
  @Published var currentOrderId: String? = nil
  @Published var orderStartStep: Int? = nil
  @Published var lastAppliedResumeForOrderId: String? = nil
  @Published var currentDestination: Destination = .startNewOrder
}
```

#### Published Properties Explained

1. **`showSplash: Bool`**: Controls splash screen visibility
2. **`showPreviousOrders: Bool`**: Controls previous orders sheet
3. **`showContactInfoDetail: Bool`**: Controls contact info detail sheet
4. **`showInternationalLongDistance: Bool`**: Controls international calling details sheet
5. **`showPrivacyPolicy: Bool`**: Controls privacy policy sheet
6. **`showTermsAndConditions: Bool`**: Controls terms and conditions sheet
7. **`currentOrderId: String?`**: Current order ID for resumption
8. **`orderStartStep: Int?`**: Step to resume at for order resumption
9. **`lastAppliedResumeForOrderId: String?`**: Tracks which order's resume step was applied
10. **`currentDestination: Destination`**: Current navigation destination

#### Key Methods

**1. `navigateTo(_ destination: Destination)`**
```swift
func navigateTo(_ destination: Destination) {
  print("DEBUG: NavigationState.navigateTo called with destination: \(destination)")
  self.currentDestination = destination
}
```
- Updates `currentDestination` to trigger navigation
- Logs navigation changes for debugging

**2. `resumeOrder(orderId: String, at step: Int)`**
```swift
func resumeOrder(orderId: String, at step: Int) {
  currentOrderId = orderId
  orderStartStep = step
  navigateTo(.orderFlow)
}
```
- Sets up order resumption state
- Navigates to order flow at specified step

**3. `showSplashScreen()`**
```swift
func showSplashScreen() {
  currentDestination = .splash
  showSplash = true
  resetNavigation()
}
```
- Shows splash screen
- Resets navigation state

**4. `reset()`**
```swift
func reset() {
  currentDestination = .splash
  showSplash = false
  // Reset all published properties
}
```
- Resets all navigation state to initial values

#### How Navigation Works

1. **State Observation**: Views observe `NavigationState` via `@EnvironmentObject`
2. **Destination Changes**: When `currentDestination` changes, observing views update
3. **ContentView Reacts**: `ContentView` listens to `currentDestination` changes and updates `orderStep`
4. **Order Resumption**: `resumeOrder()` sets `currentOrderId` and `orderStartStep`, then navigates
5. **Sheet Presentation**: Boolean flags control sheet presentations (previous orders, contact info, etc.)

---

## File Structure & Organization

### Directory Structure

```
MobileApp/MobileApp/
├── MobileApp.swift          # App entry point
├── SplashView.swift              # Initial splash screen
├── LoginView.swift               # Login screen
├── CreateAccountView.swift       # Account creation
├── ContentView.swift             # Main content router
├── NavigationState.swift         # Navigation state manager
├── OrderFlowView.swift           # Alternative order flow view
├── AppHeader.swift               # Reusable header component
├── BottomActionComponents.swift  # Bottom action bar components
├── StepNavigationComponents.swift # Step navigation components
│
├── Home/                         # Home screen views
│   ├── NewUserStartOrderView.swift
│   ├── ExistingUserStartOrderView.swift
│   ├── NewUserContactInfoView.swift
│   ├── AddressInfoSheet.swift
│   ├── PlanSelectionView.swift
│   └── InternationalLongDistanceView.swift
│
├── OrderFlow/                    # Order flow step views
│   ├── ContactInfoView.swift        # Step 1
│   ├── DeviceCompatibilityView.swift # Step 2
│   ├── SimSelectionView.swift       # Step 3
│   ├── NumberSelectionView.swift   # Step 4
│   ├── BillingInfoView.swift        # Step 5
│   ├── NumberPortingView.swift       # Step 6
│   ├── PortingView.swift
│   ├── SIMSetupView.swift
│   ├── IMEICheckView.swift
│   └── OrderDetailView.swift
│
├── Profile/                      # Profile & settings views
│   ├── ProfileView.swift
│   ├── ContactInfoDetailView.swift
│   ├── ContactInfoDetailViewModel.swift
│   ├── PreviousOrdersView.swift
│   ├── HamburgerMenuView.swift
│   ├── PrivacyPolicyView.swift
│   └── TermsAndConditionsView.swift
│
├── Models/                       # Data models
│   ├── UserRegistrationViewModel.swift
│   ├── OrderModels.swift
│   └── PhoneModels.swift
│
└── Utils/                        # Utility classes
    ├── FirebaseManager.swift
    ├── FirebaseOrderManager.swift
    ├── VCareAPIManager.swift
    ├── LocationManager.swift
    ├── NotificationManager.swift
    ├── AuthStateManager.swift
    ├── Color+Theme.swift
    ├── DebugLogger.swift
    ├── OrderStepStyle.swift
    ├── UIConstants.swift
    └── AppStoreLinking.swift
```

---

## Data Models & View Models

### UserRegistrationViewModel.swift

**Location**: `/MobileApp/MobileApp/Models/UserRegistrationViewModel.swift`

**Purpose**: Central view model managing all user and order data

#### Published Properties

**Account Information**:
```swift
@Published var accountType: String = ""
@Published var email: String = ""
@Published var password: String = ""
@Published var confirmPassword: String = ""
```

**Contact Information**:
```swift
@Published var firstName: String = ""
@Published var lastName: String = ""
@Published var phoneNumber: String = ""
```

**Shipping Address**:
```swift
@Published var street: String = ""
@Published var aptNumber: String = ""
@Published var zip: String = ""
@Published var city: String = ""
@Published var state: String = ""
@Published var country: String = "USA"
```

**Device Information**:
```swift
@Published var deviceBrand: String = ""
@Published var deviceModel: String = ""
@Published var imei: String = ""
@Published var deviceIsCompatible: Bool = false
```

**SIM & Number Selection**:
```swift
@Published var simType: String = ""  // "Physical" or "eSIM"
@Published var numberType: String = ""  // "New" or "Existing"
@Published var selectedPhoneNumber: String = ""
```

**Port-In Information**:
```swift
@Published var portInAccountNumber: String = ""
@Published var portInPin: String = ""
@Published var portInCurrentCarrier: String = ""
@Published var portInAccountHolderName: String = ""
@Published var portInSkipped: Bool = false
```

**eSIM Information**:
```swift
@Published var isForThisDevice: Bool = true
@Published var showQRCode: Bool = false
```

**Billing Information**:
```swift
@Published var creditCardNumber: String = ""
@Published var billingDetails: String = ""
@Published var address: String = ""
```

**Order Management**:
```swift
@Published var userId: String? = nil
@Published var orderId: String? = nil
@Published var previousOrders: [Order] = []
@Published var isLoading: Bool = false
@Published var errorMessage: String? = nil
```

#### Key Methods

**1. `saveContactInfo(completion:)`**
- Saves contact info to three locations:
  - `users/{userId}/contactInfo/primary`
  - `users/{userId}/shippingAddress/primary`
  - `users/{userId}/orders/{orderId}`
- Uses `DispatchGroup` to coordinate multiple async operations
- Returns success/failure via completion handler

**2. `saveDeviceInfo(completion:)`**
- Saves device information directly to order document
- Updates: `deviceBrand`, `deviceModel`, `imei`, `deviceIsCompatible`

**3. `saveSimSelection(completion:)`**
- Saves SIM type selection to order document
- Updates: `simType`

**4. `saveNumberSelection(completion:)`**
- Saves number selection to order document
- Updates: `numberType`, `selectedPhoneNumber`, port-in data if applicable
- Includes eSIM data if applicable

**5. `saveBillingInfo(completion:)`**
- Saves billing information to order document
- Updates: `creditCardNumber`, `billingDetails`, `address`, `country`

**6. `completeOrder(completion:)`**
- Marks order as completed in Firebase
- Sets `orderCompleted: true`, `status: "completed"`, `currentStep: 6`
- Calls `completeOrderReset()` to clear order-specific fields

**7. `prefillFromOrder(orderId:completion:)`**
- Fetches order document from Firebase
- Hydrates view model with existing order data
- Used for order resumption

**8. `loadUserData(completion:)`**
- Loads user data on sign-in
- Fetches from:
  - `users/{userId}` (main document)
  - `users/{userId}/contactInfo/primary`
  - `users/{userId}/shippingAddress/primary`
- Resets order-specific fields to start fresh

**9. `resetOrderSpecificFields()`**
- Resets only order-specific fields (device, SIM, number, billing)
- Preserves contact info and shipping address
- Does NOT reset `numberType` (needed for step 6 logic)

**10. `resetAllUserData()`**
- Resets ALL user data including contact info
- Called on logout

**11. `logout(completion:)`**
- Signs out from Firebase Auth
- Calls `resetAllUserData()`
- Removes persisted orderId from UserDefaults

### OrderModels.swift

**Location**: `/MobileApp/MobileApp/Models/OrderModels.swift`

#### Order Struct

```swift
struct Order: Identifiable, Codable {
  let id: String
  let userId: String
  let planName: String
  let amount: Double
  let orderDate: Date
  let status: OrderStatus
  let billingCompleted: Bool
  let phoneNumber: String?
  let simType: String
  let currentStep: Int?
}
```

**Properties**:
- `id`: Order document ID
- `userId`: User ID who created the order
- `planName`: Selected plan name
- `amount`: Plan price
- `orderDate`: Order creation date
- `status`: Order status (pending, completed, cancelled)
- `billingCompleted`: Whether billing was completed
- `phoneNumber`: Selected phone number (optional)
- `simType`: SIM type (Physical or eSIM)
- `currentStep`: Current step in order flow (1-6)

#### OrderStatus Enum

```swift
enum OrderStatus: String, Codable, CaseIterable {
  case pending = "pending"
  case completed = "completed"
  case cancelled = "cancelled"
  
  var displayName: String {
    switch self {
    case .pending: return "Pending"
    case .completed: return "Completed"
    case .cancelled: return "Cancelled"
    }
  }
}
```

#### OrderDetail Struct

Comprehensive order detail structure with all fields from the order flow:
- Personal Information (firstName, lastName, email, phoneNumber)
- Address Information (street, aptNumber, city, state, zip, country)
- Device Information (deviceBrand, deviceModel, imei, deviceIsCompatible)
- Service Information (numberType, selectedPhoneNumber, simType, portInSkipped)
- Billing Information (creditCardNumber, billingDetails)

### PhoneModels.swift

**Location**: `/MobileApp/MobileApp/Models/PhoneModels.swift`

#### PhoneBrand Enum

```swift
enum PhoneBrand: String, CaseIterable, Identifiable {
  case apple = "Apple"
  case samsung = "Samsung"
  case google = "Google"
  case oneplus = "OnePlus"
  
  var id: String { self.rawValue }
}
```

#### PhoneModel Struct

```swift
struct PhoneModel: Identifiable, Hashable {
  let id = UUID()
  let name: String
  let brand: PhoneBrand
}
```

#### PhoneCatalog Class

Singleton class providing phone catalog:
```swift
class PhoneCatalog {
  static let shared = PhoneCatalog()
  
  let allModels: [PhoneModel] = [
    // Apple models
    PhoneModel(name: "iPhone 15 Pro Max", brand: .apple),
    PhoneModel(name: "iPhone 15 Pro", brand: .apple),
    // ... more models
  ]
  
  func models(for brand: PhoneBrand) -> [PhoneModel] {
    return allModels.filter { $0.brand == brand }
  }
}
```

---

## Firebase Integration

### FirebaseManager.swift

**Location**: `/MobileApp/MobileApp/Utils/FirebaseManager.swift`

**Purpose**: Firebase Firestore operations manager

#### Firestore Structure

```
users/
  {userId}/
    - Main user document (accountType, email, createdAt, etc.)
    contactInfo/
      primary/
        - Contact info document (firstName, lastName, phoneNumber, email)
    shippingAddress/
      primary/
        - Shipping address document (street, aptNumber, city, state, zip)
    orders/
      {orderId}/
        - Complete order document with all order data
```

#### Key Methods

**User Management**:
- `saveUserRegistration(userId:data:completion:)` - Save user registration
- `updateUserRegistration(userId:data:completion:)` - Update user data
- `getUserRegistration(userId:completion:)` - Get user data

**Contact Info**:
- `saveContactInfo(userId:contactData:completion:)` - Save to contactInfo subcollection
- `getContactInfo(userId:completion:)` - Get contact info
- `saveOrderContactInfo(userId:orderId:contactData:updateUserDefault:completion:)` - Save to order
- `getOrderContactInfo(userId:orderId:completion:)` - Get from order

**Shipping Address**:
- `saveShippingAddress(userId:addressData:completion:)` - Save to shippingAddress subcollection
- `getShippingAddress(userId:completion:)` - Get shipping address
- `saveOrderShippingAddress(userId:orderId:addressData:updateUserDefault:completion:)` - Save to order
- `getOrderShippingAddress(userId:orderId:completion:)` - Get from order

**Order Management**:
- `createNewOrder(userId:planId:planName:planPrice:completion:)` - Create new order document
- `copyContactInfoToOrder(userId:orderId:completion:)` - Copy contact info to order
- `copyShippingAddressToOrder(userId:orderId:completion:)` - Copy shipping address to order
- `deleteOrder(userId:orderId:completion:)` - Delete order document

**Debug**:
- `debugUserDataLocations(userId:completion:)` - Debug function to check data locations

### FirebaseOrderManager.swift

**Location**: `/MobileApp/MobileApp/Utils/FirebaseOrderManager.swift`

**Purpose**: Order-specific Firebase operations

#### Key Methods

**1. `saveStepProgress(userId:orderId:step:data:completion:)`**
```swift
func saveStepProgress(userId: String, orderId: String, step: Int, 
                     data: [String: Any] = [:], 
                     completion: ((Result<Void, Error>) -> Void)? = nil)
```
- Saves step progress to order document
- Updates `currentStep` and `status`
- Merges additional data if provided

**2. `markOrderCompleted(userId:orderId:completion:)`**
- Marks order as completed
- Sets `status: "completed"`

**3. `fetchLatestIncompleteOrder(for:completion:)`**
- Fetches latest incomplete order (status = "pending")
- Returns orderId and currentStep
- Used for order resumption

**4. `fetchUserOrders(completion:)`**
- Fetches all orders for current user
- Returns array of `Order` objects
- Ordered by `updatedAt` descending

**5. `fetchCompletedOrders(completion:)`**
- Fetches only completed orders
- Filters by `status: "completed"`

**6. `fetchOrderDocument(orderId:completion:)`**
- Fetches single order document
- Returns raw `[String: Any]` data
- Used for order detail views and prefill

**7. `deleteOrder(orderId:completion:)`**
- Deletes order document
- Uses `FirebaseManager.shared.deleteOrder()`

---

## User Flows & Navigation Paths

### New User Flow

1. **App Launch** → `SplashView`
   - Shows logo and loading indicator
   - Checks Firebase Auth state

2. **Not Logged In** → `LoginView`
   - User can sign in or create account
   - Options: Email/Password, Google, Apple

3. **Create Account** → `CreateAccountView`
   - Account creation form
   - Same authentication options as login

4. **After Account Creation** → `SplashView` (auth check)
   - Determines if new or existing user
   - Fetches incomplete orders if any

5. **Logged In (New User)** → `ContentView` with `isNewAccount = true`
   - `orderStep = 0` → Shows `NewUserStartOrderView`

6. **New User Start Order View**
   - Displays available plans
   - User selects plan
   - Clicks "Start Order" or "Get Started" button
   - Creates order in Firebase
   - Checks if contact info exists

7. **Contact Info Check**
   - If no contact info → Shows `NewUserContactInfoView`
   - If contact info exists → Proceeds to order flow

8. **Order Flow** → `orderStep = 1`
   - Step 1: Contact Info
   - Step 2: Device Compatibility
   - Step 3: SIM Selection
   - Step 4: Number Selection
   - Step 5: Billing Info
   - Step 6: Number Porting (optional)

9. **Order Completion**
   - Order marked as completed
   - `orderStep = 0` → Returns to `NewUserStartOrderView`

### Existing User Flow

1. **App Launch** → `SplashView`
   - Checks Firebase Auth state

2. **Logged In** → `ContentView` with `isNewAccount = false`
   - `orderStep = 0` → Shows `ExistingUserStartOrderView`

3. **Existing User Start Order View**
   - Welcome message
   - Incomplete orders section (if any)
   - Plan carousel
   - Recent orders list

4. **Options**:
   - **Resume Incomplete Order**: Click "Complete Setup" → Resumes at saved step
   - **Create New Order**: Select plan → Creates new order → Starts at Step 1
   - **View Order History**: Navigate to Profile → Previous Orders

5. **Order Flow** (same as new user)

### Order Flow Navigation

**Step Progression**:
- **Step 1 → Step 2**: Next button (saves contact info)
- **Step 2 → Step 3**: Next button (saves device info)
- **Step 3 → Step 4**: Next button (saves SIM selection)
- **Step 4 → Step 5**: Next button (saves number selection)
- **Step 5 → Step 6**: Next button (saves billing info)
- **Step 6**: Complete button (completes order)

**Back Navigation**:
- **Steps 2-6**: Back button → Previous step
- **Step 1**: Back button disabled

**Cancel Navigation**:
- **Any Step**: Cancel button → Confirmation alert → Returns to home
- **Step 6**: Cancel button disabled

**Order Resumption**:
- `NavigationState.resumeOrder(orderId:at:)` sets `currentOrderId` and `orderStartStep`
- `ContentView` observes navigation changes and updates `orderStep`
- View model prefills from order document

---

## Detailed Component Documentation

### SplashView.swift

**Location**: `/MobileApp/MobileApp/SplashView.swift`

**Purpose**: Initial screen with authentication check

#### State Properties

```swift
@State private var isLoggedIn = false
@State private var isLoading = true
@State private var isNewAccount: Bool? = nil
@State private var initialOrderStep: Int? = nil
@EnvironmentObject private var navigationState: NavigationState
@StateObject private var notificationManager = NotificationManager.shared
@StateObject private var viewModel = UserRegistrationViewModel()
```

#### Flow Logic

1. **onAppear**:
   - Calls `setupSplashScreen()` - Requests notification permission, logs app opened
   - Calls `checkAuthenticationState()` - Checks Firebase Auth

2. **checkAuthenticationState()**:
   - Checks `Auth.auth().currentUser`
   - If logged in:
     - Sets `isLoggedIn = true`
     - Sets `viewModel.userId = user.uid`
     - Calls `viewModel.loadUserData()`
     - Fetches previous orders to determine if new/existing user
     - Fetches latest incomplete order
     - Sets `isNewAccount` and `initialOrderStep`
     - Shows splash for minimum time (1.6 seconds, or 0.8 if reduced motion)
   - If not logged in:
     - Sets `isLoggedIn = false`
     - Resets navigation state
     - Shows splash for minimum time

3. **View Rendering**:
   - If `isLoading`: Shows logo and ProgressView
   - If `isLoggedIn` and has account info: Shows `ContentView`
   - If not logged in: Shows `LoginView`

### LoginView.swift

**Location**: `/MobileApp/MobileApp/LoginView.swift`

**Purpose**: User authentication

#### Authentication Methods

**1. Email/Password Sign-In**:
```swift
private func signInWithEmail() {
  Auth.auth().signIn(withEmail: email, password: password) { _, error in
    if let error = error {
      show(error: error.localizedDescription)
    } else {
      onSignIn?()
    }
  }
}
```

**2. Google Sign-In**:
- Uses `GIDSignIn.sharedInstance`
- Gets ID token and access token
- Creates `GoogleAuthProvider.credential`
- Signs in with credential

**3. Apple Sign-In**:
- Uses `SignInWithAppleButton`
- Generates nonce for security
- Gets identity token
- Creates `OAuthProvider.appleCredential`
- Signs in with credential

**4. Password Reset**:
- Validates email format
- Calls `Auth.auth().sendPasswordReset(withEmail:)`
- Shows success/error message

### ContentView.swift

**Location**: `/MobileApp/MobileApp/ContentView.swift`

**Purpose**: Main content router between home and order flow

#### State Properties

```swift
let isNewAccount: Bool
let initialOrderStep: Int
@StateObject private var viewModel = UserRegistrationViewModel()
@State private var orderStep: Int
@EnvironmentObject private var navigationState: NavigationState
@State private var showExistingStart: Bool? = nil
@State private var hasContactInfo: Bool? = nil
@State private var isLoadingContactInfo: Bool = true
@State private var showContactInfoForAddressChange: Bool = false
```

#### Routing Logic

**When `orderStep == 0` (Home)**:
- Checks if contact info needed or address change requested
- If new user and no contact info: Shows `NewUserContactInfoView`
- Otherwise: Determines which start view to show
  - `showExistingStart == false`: Shows `StartOrderView` (new user)
  - `showExistingStart == true`: Shows `ExistingUserStartOrderView`

**When `orderStep > 0` (Order Flow)**:
- Switch statement based on `orderStep`:
  - `case 1`: `ContactInfoView`
  - `case 2`: `DeviceCompatibilityView`
  - `case 3`: `SimSelectionView`
  - `case 4`: `NumberSelectionView`
  - `case 5`: `BillingInfoView`
  - `case 6`: `NumberPortingView`

#### Navigation Handling

**onChange(of: navigationState.currentDestination)**:
- Listens to navigation state changes
- Updates `orderStep` based on destination:
  - `.home` or `.startNewOrder`: Sets `orderStep = 0`
  - `.orderFlow`: Sets `orderStep` from `orderStartStep` or defaults to 1
- Prefills view model if resuming order

**onAppear**:
- Sets up Firebase Auth state listener
- Loads user data
- Refreshes existing flag
- Checks contact info for new users

**handleLogout()**:
- Removes auth state listener
- Calls `viewModel.logout()`
- Resets UI state
- Shows splash screen

### NewUserStartOrderView.swift / StartOrderView

**Location**: `/MobileApp/MobileApp/Home/NewUserStartOrderView.swift`

**Purpose**: Home screen for new users to start orders

#### Features

1. **Header**:
   - Logo
   - ZIP code display (clickable to change address)
   - Hamburger menu button

2. **Content**:
   - "ALL-AMERICAN PERFORMANCE. EVERYDAY PRICE." header
   - "The 47 plan" badge
   - Available plans list (first 3 plans)
   - "View All Plans" button if more than 3
   - Features list:
     - Unlimited Talk, Text & Data
     - Free SIM Kit + Shipping
     - No Contract – Cancel Anytime
     - Bring Your Own Phone
     - International Calling to 100 destinations
     - No Credit Check

3. **Bottom Button**:
   - "Start Order" or "Get Started" button
   - Fixed at bottom using `BottomActionBar`

#### Key Functions

**createNewOrder()**:
1. Gets current user ID
2. Gets selected plan information
3. Calls `FirebaseManager.shared.createNewOrder()` to create order document
4. Copies contact info to order (if exists)
5. Copies shipping address to order (if exists)
6. Calls `onStart(orderId)` to proceed to order flow

**loadPlans()**:
1. Gets user ID
2. Gets ZIP code from shipping address or contact info
3. Calls `VCareAPIManager.shared.getPlanList()` with ZIP code
4. Updates `availablePlans` state
5. Auto-selects first plan if none selected

**loadAddressInfo()**:
1. Gets user ID
2. Fetches shipping address from Firebase
3. Updates `currentZipCode` and `currentAddress`
4. Reloads plans if ZIP code changed

### ExistingUserStartOrderView.swift

**Location**: `/MobileApp/MobileApp/Home/ExistingUserStartOrderView.swift`

**Purpose**: Home screen for existing users

#### Features

1. **Header**: Same as new user view

2. **Welcome Section**:
   - "Welcome back!" message
   - "Here's your dashboard." subtitle

3. **Incomplete Orders Section**:
   - Shows orders that need completion
   - Horizontal scroll for multiple orders
   - Each card shows:
     - Order ID
     - Start date
     - Phone number
     - SIM type
     - Device info
     - Missing tasks
   - "Complete Setup" button to resume

4. **Plans Section**:
   - Carousel view showing one plan at a time
   - Auto-rotates every 5 seconds
   - Page indicators
   - Tap to select plan
   - Shows plan details sheet

5. **Recent Orders Section**:
   - Shows last 3 orders
   - Order cards with status indicators
   - "View all orders in Profile" link

#### Key Functions

**loadIncompleteOrders()**:
- Queries orders where `portInSkipped == true`
- Maps to `IncompleteOrder` structs
- Determines missing tasks

**completeOrderSetup(orderId:)**:
- Calls `onStart?(orderId)` to resume order

**createNewOrderAndStart()**:
- Creates new order in Firebase
- Calls `onStart?(orderId)` to start order flow

**startCarouselTimer()**:
- Creates timer to auto-rotate plans every 5 seconds
- Stops when user manually selects plan

### Order Flow Views

#### ContactInfoView.swift (Step 1)

**Location**: `/MobileApp/MobileApp/OrderFlow/ContactInfoView.swift`

**Purpose**: Collect contact and shipping information

**Fields**:
- First Name
- Last Name
- Phone Number (formatted as (000) 000-0000)
- Email (read-only from auth)
- Street Address
- Apt/Suite (optional)
- City
- State
- ZIP Code

**Features**:
- Location-based autofill checkbox
- Phone number formatting
- Validation (all required fields must be filled)
- Location permission handling

**Actions**:
- Next button: Saves contact info to Firebase, advances to Step 2
- Cancel button: Returns to home

#### DeviceCompatibilityView.swift (Step 2)

**Location**: `/MobileApp/MobileApp/OrderFlow/DeviceCompatibilityView.swift`

**Purpose**: Device information and compatibility check

**Fields**:
- Device Brand (dropdown: Apple, Samsung, Google, OnePlus)
- Device Model (dropdown: filtered by brand)
- IMEI (optional, with check button)

**Features**:
- Brand selection updates available models
- IMEI compatibility check
- Device compatibility verification

**Actions**:
- Next button: Saves device info, advances to Step 3
- Back button: Returns to Step 1
- Cancel button: Returns to home

#### SimSelectionView.swift (Step 3)

**Location**: `/MobileApp/MobileApp/OrderFlow/SimSelectionView.swift`

**Purpose**: SIM type selection

**Options**:
- eSIM
- Physical SIM

**Features**:
- Detects eSIM-only devices (iPhone 14/15 in USA)
- Disables Physical SIM option for eSIM-only devices
- Visual selection with gradient buttons

**Actions**:
- Next button: Saves SIM selection, advances to Step 4
- Back button: Returns to Step 2
- Cancel button: Returns to home

#### NumberSelectionView.swift (Step 4)

**Location**: `/MobileApp/MobileApp/OrderFlow/NumberSelectionView.swift`

**Purpose**: Phone number selection

**Options**:
- Transfer Existing Number (port-in)
- Choose New Number

**Features**:
- If "Existing": Shows port-in form:
  - Account Number
  - PIN
  - Current Carrier
  - Account Holder Name
- If "New": Shows number selection UI
- eSIM QR code option if eSIM selected

**Actions**:
- Next button: Saves number selection, advances to Step 5
- Back button: Returns to Step 3
- Cancel button: Returns to home

#### BillingInfoView.swift (Step 5)

**Location**: `/MobileApp/MobileApp/OrderFlow/BillingInfoView.swift`

**Purpose**: Billing information collection

**Fields**:
- Credit Card Number (formatted)
- Expiration Date (MM/YY format)
- CVV
- Billing Address (can use shipping address)
- E911 Agreement checkbox
- Recurring Charge Agreement checkbox
- Privacy Terms Agreement checkbox

**Features**:
- Credit card number formatting
- Form validation
- Plan information display
- Agreement checkboxes

**Actions**:
- "Complete Order" button: Saves billing info, advances to Step 6
- Back button: Returns to Step 4
- Cancel button: Returns to home

#### NumberPortingView.swift (Step 6)

**Location**: `/MobileApp/MobileApp/OrderFlow/NumberPortingView.swift`

**Purpose**: Number porting and SIM setup (final step)

**Flow**:
- If transferring existing number: Shows `PortingView` first
- Then shows `SIMSetupView`
- If new number: Shows `SIMSetupView` directly

**Actions**:
- Complete button: Marks order as completed, returns to home
- Back button: Returns to Step 5
- Cancel button: Returns to home

---

## State Management

### State Management Strategy

The app uses a combination of state management approaches:

1. **Local State (`@State`)**:
   - View-specific state that doesn't need to be shared
   - Examples: `isLoading`, `errorMessage`, `showSheet`

2. **View Model State (`@StateObject`, `@ObservedObject`)**:
   - `@StateObject`: Creates and owns the view model
   - `@ObservedObject`: Observes an existing view model
   - Examples: `UserRegistrationViewModel`, `ContactInfoDetailViewModel`

3. **Global State (`@EnvironmentObject`)**:
   - App-wide state shared across views
   - Examples: `NavigationState`, `UserRegistrationViewModel` (injected at app level)

4. **Published Properties (`@Published`)**:
   - Properties that trigger view updates when changed
   - Used in `ObservableObject` classes

### State Flow

```
App Level (MobileApp)
  ├── NavigationState (@StateObject) → @EnvironmentObject
  ├── UserRegistrationViewModel (@StateObject) → @EnvironmentObject
  └── ContactInfoDetailViewModel (@StateObject) → @EnvironmentObject

View Level
  ├── ContentView
  │   ├── @EnvironmentObject navigationState
  │   ├── @StateObject viewModel (local instance)
  │   └── @State orderStep
  │
  └── Order Flow Views
      ├── @ObservedObject viewModel
      └── @State localState
```

### State Synchronization

1. **Navigation State**: 
   - `NavigationState` is observed by `ContentView`
   - Changes to `currentDestination` trigger `orderStep` updates

2. **Order Data**:
   - `UserRegistrationViewModel` holds all order data
   - Views observe view model via `@ObservedObject`
   - Changes to `@Published` properties trigger view updates

3. **Order Resumption**:
   - `NavigationState` stores `currentOrderId` and `orderStartStep`
   - `ContentView` reads these and updates `orderStep`
   - View model prefills from order document

---

## API Integration

### VCareAPIManager.swift

**Location**: `/MobileApp/MobileApp/Utils/VCareAPIManager.swift`

**Purpose**: VCare API integration for plan data

#### Plan Model

```swift
struct Plan: Codable, Identifiable {
    let plan_id: Int
    let plan_name: String
    let plan_price: Int
    let total_plan_price: Int
    let plan_description: String
    let display_name: String?
    let display_description: String?
    let display_features_description: [String]
    let data: Int  // MB
    let talk: Int  // Minutes
    let text: Int  // Messages
    let is_unlimited_plan: String
    let is_familyplan: String
    let is_prepaid_postpaid: String
    let plan_expiry_days: Int
    let plan_expiry_type: String
    let carrier: [String]
    let plan_discount_details: [String]
    let autopay_discount: String
}
```

#### API Method

**getPlanList(zipCode:enrollmentType:isFamilyPlan:agentId:source:completion:)**:
```swift
func getPlanList(zipCode: String, 
                enrollmentType: String, 
                isFamilyPlan: String, 
                agentId: String, 
                source: String, 
                completion: @escaping (Result<[Plan], Error>) -> Void)
```

**Parameters**:
- `zipCode`: User's ZIP code (determines available plans)
- `enrollmentType`: "NON_LIFELINE" or "LIFELINE"
- `isFamilyPlan`: "Y" or "N"
- `agentId`: Agent identifier ("Sushil")
- `source`: "API"

**Response**:
- Success: Array of `Plan` objects
- Failure: Error object

**Usage**:
- Called from `StartOrderView.loadPlans()`
- Called from `ExistingUserStartOrderView.loadPlans()`
- ZIP code retrieved from Firebase shipping address

---

## UI Components & Styling

### Color+Theme.swift

**Location**: `/MobileApp/MobileApp/Utils/Color+Theme.swift`

**Purpose**: App-wide color theme and styling

#### Custom Colors

```swift
extension Color {
  static let accentGold = Color("AccentColor")
  static let accentGold2 = Color("AccentColor2")
  static let appPrimary = Color("AppPrimary")
  static let appBackground = Color("BackgroundColor")
  static let appText = Color("TextColor")
  static let appSecondary = Color("SecondaryCustom")
  
  // Adaptive colors
  static let adaptiveBackground = Color(.systemBackground)
  static let adaptiveSecondaryBackground = Color(.secondarySystemBackground)
  static let adaptiveTertiaryBackground = Color(.tertiarySystemBackground)
  static let adaptiveText = Color(.label)
  static let adaptiveSecondaryText = Color(.secondaryLabel)
  static let adaptiveBorder = Color(.systemGray4)
}
```

#### Button Styles

**GradientButtonStyle**:
- Linear gradient from `accentGold` to `accentGold2`
- White text
- Rounded corners
- Opacity change on press

### StepNavigationComponents.swift

**Location**: `/MobileApp/MobileApp/StepNavigationComponents.swift`

**Purpose**: Reusable navigation components for order flow

#### Components

**1. StepIndicatorText**:
- Displays "Step X of 6"
- Capsule shape with gradient background
- White text

**2. StepNavigationContainer**:
- Container for order flow steps
- Includes:
  - Header with back button, step indicator, cancel button
  - Scrollable content area
  - Fixed bottom action bar
- Parameters:
  - `currentStep`: Current step number (1-6)
  - `totalSteps`: Total steps (default: 6)
  - `nextButtonText`: Text for next button
  - `nextButtonDisabled`: Whether next button is disabled
  - `nextButtonAction`: Action for next button
  - `backButtonAction`: Action for back button
  - `cancelAction`: Action for cancel button
  - `content`: ViewBuilder for step content

**3. StepNavigationButton**:
- Gradient button for navigation
- Shows chevron icon (left for back, right for next)
- Disabled state styling

**4. NavigationButtonsView**:
- Container for navigation buttons
- Used for step navigation

### BottomActionComponents.swift

**Location**: `/MobileApp/MobileApp/BottomActionComponents.swift`

**Purpose**: Bottom action bar components

#### Components

**1. PrimaryGradientButton**:
- Gradient button with title
- Disabled state support
- Action closure

**2. BottomActionBar**:
- Fixed bottom bar container
- Standardized padding and styling
- Background color matching app theme

### AppHeader.swift

**Location**: `/MobileApp/MobileApp/AppHeader.swift`

**Purpose**: Reusable header component

**Features**:
- Customizable content via `@ViewBuilder`
- Fixed height
- Background color: `appBackground`
- Standardized padding

**Usage**:
- Logo display
- Navigation buttons
- ZIP code display
- Menu buttons

---

## Utility Classes & Helpers

### LocationManager.swift

**Location**: `/MobileApp/MobileApp/Utils/LocationManager.swift`

**Purpose**: Location services for address autofill

**Features**:
- Location authorization handling
- Location fetching
- Reverse geocoding (coordinates → address)
- Authorization status tracking

**Usage**:
- Used in `ContactInfoView` and `NewUserContactInfoView`
- Autofills shipping address from device location

### NotificationManager.swift

**Location**: `/MobileApp/MobileApp/Utils/NotificationManager.swift`

**Purpose**: Local notifications management

**Features**:
- Permission requests
- Welcome notifications
- Analytics logging (app opened, order started, step completed, order completed)

**Usage**:
- Called from `SplashView.setupSplashScreen()`
- Sends welcome notification after sign-in

### AuthStateManager.swift

**Location**: `/MobileApp/MobileApp/Utils/AuthStateManager.swift`

**Purpose**: Firebase Auth state management

**Features**:
- Auth state listeners
- Auth persistence
- State change notifications

**Usage**:
- Initialized in `AppDelegate`
- Used throughout app for auth state checks

### DebugLogger.swift

**Location**: `/MobileApp/MobileApp/Utils/DebugLogger.swift`

**Purpose**: Debug logging utility

**Features**:
- Categorized logging
- User action logging
- User info retrieval logging
- Debug output formatting

**Usage**:
- Used throughout app for debugging
- Logs user actions and data retrieval

### OrderStepStyle.swift

**Location**: `/MobileApp/MobileApp/Utils/OrderStepStyle.swift`

**Purpose**: Order step styling constants

**Features**:
- Layout constants (padding, spacing)
- Style definitions
- Reusable styling values

### UIConstants.swift

**Location**: `/MobileApp/MobileApp/Utils/UIConstants.swift`

**Purpose**: UI constants

**Features**:
- Header height constants
- Spacing constants
- Layout constants

### AppStoreLinking.swift

**Location**: `/MobileApp/MobileApp/Utils/AppStoreLinking.swift`

**Purpose**: App Store linking utilities

**Features**:
- App Store URL generation
- Deep linking support

---

## Additional Components

### Profile Views

#### ProfileView.swift
- User profile display
- Account information
- Settings access

#### ContactInfoDetailView.swift
- Contact information details and editing
- Uses `ContactInfoDetailViewModel`

#### PreviousOrdersView.swift
- Order history list
- Filter by status
- Order detail navigation

#### HamburgerMenuView.swift
- Side menu overlay
- Menu items:
  - Profile
  - Previous Orders
  - Contact Info
  - International Long Distance
  - Privacy Policy
  - Terms and Conditions
  - Logout

#### PrivacyPolicyView.swift
- Privacy policy content
- Scrollable text view

#### TermsAndConditionsView.swift
- Terms and conditions content
- Scrollable text view

### Home Views

#### AddressInfoSheet.swift
- Address editing sheet
- ZIP code change
- Address validation

#### PlanSelectionView.swift
- Full plan selection view
- All available plans
- Plan filtering and sorting

#### InternationalLongDistanceView.swift
- International calling destinations
- Rate information
- Country list

### Order Flow Views

#### PortingView.swift
- Number porting form
- Port-in information collection
- Validation

#### SIMSetupView.swift
- SIM setup instructions
- QR code display for eSIM
- Physical SIM shipping info

#### IMEICheckView.swift
- IMEI compatibility check
- IMEI validation
- Compatibility result display

#### OrderDetailView.swift
- Order details display
- Complete order information
- Order status

---

## Data Flow & Persistence

### Data Flow

1. **User Input** → View Model (`@Published` properties)
2. **View Model** → Firebase (via `FirebaseManager` or `FirebaseOrderManager`)
3. **Firebase** → Firestore (persistent storage)
4. **Firestore** → View Model (on load/resume)
5. **View Model** → View (via `@Published` updates)

### Persistence Strategy

1. **User Data**:
   - Stored in `users/{userId}` document
   - Contact info: `users/{userId}/contactInfo/primary`
   - Shipping address: `users/{userId}/shippingAddress/primary`

2. **Order Data**:
   - Stored in `users/{userId}/orders/{orderId}` document
   - Complete order data in single document
   - Step progress saved incrementally

3. **Local Persistence**:
   - `UserDefaults` for `currentOrderId`
   - Firebase Auth persistence (automatic)

### Data Synchronization

- **Real-time**: Firebase Auth state changes trigger updates
- **On-demand**: Order data loaded when needed
- **Incremental**: Step progress saved after each step
- **Resume**: Order data prefilled from Firestore on resumption

---

## Error Handling

### Error Handling Strategy

1. **Network Errors**:
   - Firebase operations return errors in completion handlers
   - Errors displayed to user via alerts or error messages

2. **Validation Errors**:
   - Form validation before submission
   - Error messages shown inline

3. **Auth Errors**:
   - Firebase Auth errors caught and displayed
   - Password reset errors handled

4. **API Errors**:
   - VCare API errors caught and logged
   - Fallback to default plans if API fails

### Error Display

- **Alerts**: Critical errors (login failures, order creation failures)
- **Inline Messages**: Form validation errors
- **Toast Messages**: Success/error feedback
- **Loading States**: Progress indicators during async operations

---

## Testing & Debugging

### Debug Features

1. **Debug Logging**:
   - `DebugLogger` for categorized logging
   - Console output for debugging

2. **Firebase Analytics Debug**:
   - Enabled in `AppDelegate`
   - Faster FIAM testing

3. **Navigation Debug**:
   - Navigation state changes logged
   - Order resumption tracked

### Testing Considerations

1. **Unit Tests**: View models and utility classes
2. **Integration Tests**: Firebase operations
3. **UI Tests**: User flows and navigation
4. **Manual Testing**: Order flow, authentication, order resumption

---

## Security Considerations

### Firebase Security Rules

- User data accessible only by authenticated user
- Order data scoped to user's own orders
- Contact info and shipping address protected

### Data Privacy

- Sensitive data (credit cards) stored securely
- User authentication required for all operations
- Location data used only for address autofill

### Authentication Security

- Secure password handling
- OAuth providers (Google, Apple) for secure sign-in
- Firebase Auth handles token management

---

## Performance Optimization

### Optimization Strategies

1. **Lazy Loading**:
   - Plans loaded on demand
   - Order data loaded when needed

2. **Image Optimization**:
   - Asset catalog for images
   - Appropriate image sizes

3. **State Management**:
   - Efficient `@Published` usage
   - Minimal state updates

4. **Firebase Queries**:
   - Indexed queries
   - Limited result sets
   - Efficient data structures

---

## Future Enhancements

### Potential Improvements

1. **Offline Support**:
   - Cache order data locally
   - Sync when online

2. **Push Notifications**:
   - Order status updates
   - Plan reminders

3. **Enhanced Analytics**:
   - User behavior tracking
   - Conversion funnel analysis

4. **Multi-language Support**:
   - Localization
   - Internationalization

5. **Accessibility**:
   - VoiceOver support
   - Dynamic Type support
   - Color contrast improvements

---

## Conclusion

This documentation provides a comprehensive overview of the mobile app architecture, components, and implementation details. The app follows modern SwiftUI patterns with MVVM architecture, centralized state management, and Firebase backend integration. The 6-step order flow provides a structured user experience with progress tracking and order resumption capabilities.

For questions or clarifications, refer to the specific file documentation or contact the development team.

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: Development Team

