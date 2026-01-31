# Authentication Architecture: Main App + ShelfLife

## Overview

A Rails main app handles billing and provisioning, while individual K3s-deployed ShelfLife instances (personal library management) handle day-to-day user access. This document outlines the authentication strategy that balances security, UX, and architectural simplicity.

## Architecture Summary

- **Main App**: Handles subscriptions, billing, and provisioning. Uses magic link authentication only.
- **ShelfLife**: Handles library management and daily user access. Uses traditional email/password authentication.
- **Owner**: Has accounts in both apps, seamlessly linked via magic links for billing access.
- **Team Members**: Only have accounts in ShelfLife.

## User Types

### Owner (Purchaser)
- Creates account on main app during subscription purchase
- Gets provisioned account on ShelfLife automatically
- Primary authentication via ShelfLife (password)
- Accesses main app via magic link for billing management
- Role: Full admin in ShelfLife + billing access in main app

### Team Members
- Only exist in ShelfLife
- Standard email/password authentication
- Never interact with main app
- Roles: Admin, Member, Viewer (defined in ShelfLife)

## Authentication Flows

### 1. Initial Provisioning (Day 0)

```
User signs up on mainapp.com
         ↓
Purchases subscription
         ↓
Main app provisions K3s instance with environment variables
         ↓
ShelfLife reads OWNER_EMAIL from environment on first boot
         ↓
ShelfLife sends password setup email
         ↓
Owner sets password on ShelfLife
         ↓
Owner starts using library
```

**Code Example:**

```ruby
# Main app - after subscription created
def provision_client_app
  subscription = Subscription.create!(user: current_user, ...)
  
  # Deploy K3s instance with environment variables
  K8sDeployer.deploy(
    namespace: subscription.namespace,
    domain: subscription.domain,
    env: {
      OWNER_EMAIL: current_user.email,
      SUBSCRIPTION_TOKEN: subscription.token,
      MAIN_APP_API_URL: Rails.application.config.main_app_url
    }
  )
end

# ShelfLife - initializer or first-boot setup
class SetupOwnerAccount
  def self.run
    return if SubscriptionConfig.exists? # Already set up
    
    owner_email = ENV['OWNER_EMAIL']
    subscription_token = ENV['SUBSCRIPTION_TOKEN']
    
    return unless owner_email.present?
    
    SubscriptionConfig.create!(
      subscription_token: subscription_token,
      owner_email: owner_email,
      main_app_api_url: ENV['MAIN_APP_API_URL']
    )
    
    # Send password setup email
    SetupMailer.welcome(
      email: owner_email,
      setup_url: setup_url(token: generate_setup_token)
    ).deliver_now
  end
end

# Call in config/initializers/setup.rb or on first web request
Rails.application.config.after_initialize do
  SetupOwnerAccount.run if Rails.env.production?
end
```

### 2. Daily Usage (Owner & Team Members)

```
User visits ShelfLife domain (janeslibrary.com)
         ↓
Logs in with email/password
         ↓
Access library features
```

Standard authentication - all handled by ShelfLife.

### 3. Billing Management (Owner Only)

```
Owner clicks "Manage Subscription" in ShelfLife
         ↓
ShelfLife calls main app API to send magic link
         ↓
Owner receives email with magic link
         ↓
Owner clicks link → auto-logged into main app
         ↓
Owner manages billing/subscription
         ↓
Redirected back to ShelfLife
```

**Code Example:**

```ruby
# ShelfLife - settings page
class SubscriptionManagementController < ApplicationController
  def request_billing_access
    MainAppApi.send_magic_link(
      email: current_user.email,
      subscription_id: current_user.subscription_id,
      return_to: request.base_url
    )
    
    flash[:notice] = "Check your email for a link to manage your subscription"
    redirect_to settings_path
  end
end

# Main app API
class Api::MagicLinksController < ApplicationController
  def send_link
    verify_client_app_signature!
    
    subscription = Subscription.find(params[:subscription_id])
    user = subscription.user
    
    token = user.generate_magic_link_token(expires_in: 15.minutes)
    
    UserMailer.billing_access_link(
      user,
      magic_url: magic_auth_url(token: token),
      return_to: params[:return_to]
    ).deliver_now
    
    head :ok
  end
end

# Main app - magic link verification
class MagicAuthController < ApplicationController
  def verify
    token = MagicLinkToken.find_by(token: params[:token])
    
    if token&.valid?
      sign_in(token.user)
      token.destroy # Single-use
      redirect_to billing_path(return_to: params[:return_to])
    else
      redirect_to root_path, alert: "Invalid or expired link"
    end
  end
end
```

### 4. Team Member Invitation

```
Owner/Admin invites team member in ShelfLife
         ↓
ShelfLife sends invitation email
         ↓
Team member clicks link, sets password
         ↓
Team member logs into ShelfLife
```

Standard invitation flow - entirely within ShelfLife.

## API Authentication (ShelfLife → Main App)

When the ShelfLife needs to call the main app API (e.g., to request a magic link), it uses a simple obfuscated subscription ID. The main app only allows one action: send a magic link to the subscription owner.

### Environment Variables (Set During Provisioning)

```bash
MAIN_APP_API_URL=https://mainapp.com
SUBSCRIPTION_TOKEN=sub_a8f3k2m9x7p4q1r6  # Obfuscated subscription ID
```

The `SUBSCRIPTION_TOKEN` is a non-guessable identifier that maps to a subscription in the main app.

### ShelfLife Request

```ruby
# ShelfLife - calling main app API
class MainAppApi
  def self.send_owner_magic_link(return_to:)
    HTTParty.post(
      "#{ENV['MAIN_APP_API_URL']}/api/subscriptions/#{ENV['SUBSCRIPTION_TOKEN']}/magic_link",
      body: { return_to: return_to }.to_json,
      headers: {
        'Content-Type' => 'application/json'
      }
    )
  end
end

# In the controller
class SubscriptionManagementController < ApplicationController
  def request_billing_access
    response = MainAppApi.send_owner_magic_link(return_to: request.base_url)
    
    if response.success?
      flash[:notice] = "Check your email for a link to manage your subscription"
    else
      flash[:error] = "Unable to send magic link. Please try again."
    end
    
    redirect_to settings_path
  end
end
```

### Main App API Endpoint

```ruby
# Main app API endpoint
class Api::Subscriptions::MagicLinksController < ApplicationController
  before_action :check_rate_limit!
  
  def create
    subscription = Subscription.find_by!(token: params[:subscription_token])
    user = subscription.user
    
    # Only action: send magic link to subscription owner
    token = user.generate_magic_link_token(expires_in: 15.minutes)
    
    UserMailer.billing_access_link(
      user,
      magic_url: magic_auth_url(token: token),
      return_to: params[:return_to]
    ).deliver_now
    
    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
  
  private
  
  def check_rate_limit!
    key = "magic_link_requests:#{params[:subscription_token]}"
    
    # Allow 5 requests per hour per subscription
    count = Rails.cache.read(key).to_i
    
    if count >= 5
      render json: { error: 'Rate limit exceeded' }, status: :too_many_requests
      return
    end
    
    Rails.cache.increment(key, 1, expires_in: 1.hour)
  end
end

# routes.rb
namespace :api do
  namespace :subscriptions do
    post ':subscription_token/magic_link', to: 'magic_links#create'
  end
end
```

### Subscription Token Generation

```ruby
# Main app - when creating subscription
class Subscription < ApplicationRecord
  before_create :generate_token
  
  private
  
  def generate_token
    # Generate a URL-safe, non-guessable token
    loop do
      self.token = "sub_#{SecureRandom.urlsafe_base64(20)}"
      break unless Subscription.exists?(token: token)
    end
  end
end

# Add to subscriptions table
add_column :subscriptions, :token, :string, null: false
add_index :subscriptions, :token, unique: true
```

### Security Features

1. **Non-Guessable Token**
   - 20 bytes of random data = 160 bits of entropy
   - URL-safe base64 encoding
   - Collision checking ensures uniqueness
   - Example: `sub_a8f3k2m9x7p4q1r6vN8KzP2L`

2. **Single Action Only**
   - API endpoint can ONLY send magic link to owner
   - No email parameter - always sends to subscription.user.email
   - No ability to access other user data
   - Token can't be used for any other operations

3. **Rate Limiting**
   - 5 requests per hour per subscription
   - Prevents abuse even if token is leaked
   - Based on subscription token, not IP

4. **Implicit Authorization**
   - Possession of token = authorization
   - No complex signature verification needed
   - Simple and secure for this single-purpose use case

### Why This Is Secure

**The token is essentially a capability:**
- It grants one capability: "send magic link to this subscription's owner"
- Even if leaked, an attacker can only spam the owner with magic links
- They can't access the account (magic link goes to owner's email)
- They can't modify data or perform other actions
- Rate limiting prevents DoS

**Compared to HMAC:**
- Much simpler to implement
- Easier to understand and maintain
- Sufficient security for a single-action API
- No timestamp synchronization issues
- No signature verification bugs

### Example Token Format

```
sub_a8f3k2m9x7p4q1r6vN8KzP2L
│   └─────────┬──────────────┘
│             └─ 20 bytes of random data (base64)
└─ Prefix for easy identification
```

## Database Schema

### Main App

```ruby
# users table
create_table :users do |t|
  t.string :email, null: false
  # No password field - magic link only
  t.timestamps
end

# subscriptions table
create_table :subscriptions do |t|
  t.references :user, null: false
  t.string :domain # e.g., janeslibrary.com
  t.string :status # active, cancelled, etc.
  t.string :plan
  t.string :token, null: false # Obfuscated ID for API access
  t.timestamps
  
  t.index :token, unique: true
end

# magic_link_tokens table
create_table :magic_link_tokens do |t|
  t.references :user, null: false
  t.string :token, null: false
  t.datetime :expires_at, null: false
  t.string :return_to
  t.timestamps
  
  t.index :token, unique: true
end
```

### ShelfLife

```ruby
# users table
create_table :users do |t|
  t.string :email, null: false
  t.string :encrypted_password # Devise/bcrypt
  t.boolean :is_owner, default: false # Owner = true
  t.string :role # 'owner', 'admin', 'member', 'viewer'
  t.timestamps
end

# subscription_config table (singleton - populated from environment variables)
create_table :subscription_configs do |t|
  t.string :subscription_token, null: false # from ENV['SUBSCRIPTION_TOKEN']
  t.string :owner_email, null: false # from ENV['OWNER_EMAIL']
  t.string :main_app_api_url # from ENV['MAIN_APP_API_URL']
  t.timestamps
end
```

## Security Considerations

### Magic Link Security
- ✅ Tokens expire in 15 minutes
- ✅ Single-use tokens (deleted after use)
- ✅ Cryptographically secure random tokens
- ✅ Email verification layer
- ✅ HTTPS only

### API Security (Between Apps)
- ✅ Non-guessable subscription tokens (160 bits of entropy)
- ✅ Single-action API (can only send magic link to owner)
- ✅ Rate limiting (5 requests/hour per subscription)
- ✅ No ability to specify email or perform other actions
- ✅ Token treated as capability-based authorization
- ✅ Audit logging of all API calls

### Password Security (ShelfLife)
- ✅ Bcrypt with appropriate cost factor
- ✅ Password strength requirements
- ✅ Rate limiting on login attempts
- ✅ Account lockout after failed attempts

## Email Templates

### ShelfLife - Password Setup Email

```
Subject: Your library is ready!

Welcome! Your personal library is ready at janeslibrary.com

Set your password to get started:
[Set Password]

This link expires in 24 hours.

Questions? Reply to this email.
```

### Main App - Magic Link Email

```
Subject: Access your subscription settings

Click to manage your subscription:
[Manage Subscription]

This link expires in 15 minutes.
Didn't request this? Ignore this email.

After managing your subscription, you'll be returned to janeslibrary.com
```

## Implementation Checklist

### Main App
- [ ] Remove password authentication (magic link only)
- [ ] Implement magic link token generation and verification
- [ ] Add `token` column to subscriptions table
- [ ] Generate unique subscription token on creation
- [ ] Create API endpoint: POST /api/subscriptions/:token/magic_link
- [ ] Add subscription provisioning logic with environment variables
- [ ] Implement return_to parameter handling
- [ ] Add rate limiting (5 requests/hour per subscription token)
- [ ] Add audit logging for API calls

### ShelfLife
- [ ] Implement standard email/password authentication (Devise)
- [ ] Add initializer to read environment variables on first boot
- [ ] Create SubscriptionConfig model and setup logic
- [ ] Add "Manage Subscription" button in settings
- [ ] Implement MainAppApi client (simple POST with token in URL)
- [ ] Add password setup flow for new owners
- [ ] Create team member invitation system
- [ ] Store subscription_token and owner_email from environment variables
- [ ] Add role-based access control

### Both Apps
- [ ] Set up HTTPS/TLS certificates
- [ ] Configure environment variables securely (Kubernetes secrets)
- [ ] Set up audit logging
- [ ] Configure rate limiting
- [ ] Add monitoring/alerting for API calls
- [ ] Write integration tests for cross-app flows
- [ ] Document API endpoint and responses
- [ ] Test API with invalid/missing tokens

## Benefits of This Architecture

✅ **Simple UX**: Owner has one primary password (ShelfLife), magic links for rare billing tasks  
✅ **Security**: Credentials isolated between apps, email verification for sensitive actions  
✅ **Autonomy**: ShelfLife can operate independently if main app is down  
✅ **Clear Separation**: Main app = billing, ShelfLife = features  
✅ **Scalable**: Easy to add team members without touching main app  
✅ **Maintainable**: Each app has focused responsibilities  

## Alternative Approaches Considered

### Full SSO/OIDC
**Rejected because**: Adds complexity, makes main app a single point of failure for all logins, team members don't need main app access.

### Copied Password Hashes
**Rejected because**: Security concerns (credential sharing), synchronization complexity, violates credential isolation principles.

### Two Separate Accounts with Manual Login
**Rejected because**: Poor UX (owner needs to remember two passwords), confusing for users.

## Support Scenarios

### "I forgot my password"
- **If owner**: Reset on ShelfLife (where they log in daily)
- **If team member**: Reset on ShelfLife

### "I can't access billing"
- **If owner**: Click "Manage Subscription" → check email for magic link
- **If team member**: They shouldn't have billing access

### "I want to change my email"
- **If owner**: Need to update in both apps (implement sync or manual process)
- **If team member**: Update in ShelfLife only

### "I want to cancel my subscription"
- **If owner**: Use magic link to access main app billing
- **If team member**: They can't (by design)
