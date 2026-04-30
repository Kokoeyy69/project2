# Firebase Configuration

This directory contains Firebase security rules and configurations for NeoPay AI.

## Files

- **firestore.rules** - Firestore security rules (user data & transactions)
- **storage.rules** - Firebase Storage security rules (profile photos)
- **SECURITY_AUDIT.md** - Comprehensive security audit documentation

## Deployment

### Prerequisites
```bash
npm install -g firebase-tools
firebase login
```

### Deploy Rules
```bash
# Deploy all rules
firebase deploy

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only Storage rules
firebase deploy --only storage

# Dry run (preview changes)
firebase deploy --dry-run
```

## Key Security Features

✅ User-scoped data access (Firestore & Storage)  
✅ Transaction immutability (audit trail)  
✅ File size & type validation (Storage)  
✅ Default-deny policy (security best practice)  
✅ Email verification requirement (Auth)  
✅ Rate limiting (prevents brute force)  

## Monitoring

See `SECURITY_AUDIT.md` for:
- Deployment checklist
- Monitoring recommendations
- Risk assessment matrix
- Next steps

## Support

For questions, refer to:
- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/start)
- [Storage Security Rules](https://firebase.google.com/docs/storage/security)
