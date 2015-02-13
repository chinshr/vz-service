# Determines if a user needs to register (as beta) first before she can
# sign up as new user.
User.force_registration_validation = !Rails.env.test?