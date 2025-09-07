#!/bin/bash

# DNS Fix Script for Cloudflare Tunnel
# This script fixes DNS resolution issues by ensuring the CNAME record is properly proxied

set -e

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "❌ .env file not found in $SCRIPT_DIR"
    exit 1
fi

echo "🔧 Fixing DNS Resolution for $TUNNEL_HOSTNAME..."
echo ""

# Validate required variables
if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ] || [ -z "$DNS_RECORD_ID" ] || [ -z "$TUNNEL_ID" ]; then
    echo "❌ Missing required environment variables. Please run cloudflare-tunnel-setup.sh first."
    exit 1
fi

# Step 1: Check current DNS record status
echo "🔍 Checking current DNS record status..."
CURRENT_RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$TUNNEL_HOSTNAME" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")

echo "📊 Current record status:"
echo "$CURRENT_RECORD" | jq -r '.result[] | "   Type: \(.type), Content: \(.content), Proxied: \(.proxied)"' 2>/dev/null || \
echo "$CURRENT_RECORD" | grep -o '"type":"[^"]*"' | cut -d'"' -f4 | while read type; do
    content=$(echo "$CURRENT_RECORD" | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
    proxied=$(echo "$CURRENT_RECORD" | grep -o '"proxied":[^,}]*' | cut -d':' -f2)
    echo "   Type: $type, Content: $content, Proxied: $proxied"
done

echo ""

# Step 2: Update DNS record to enable proxy (orange cloud)
echo "🔧 Updating DNS record to enable proxy (orange cloud)..."
HOSTNAME_PART=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f1)

UPDATE_RESULT=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$DNS_RECORD_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\": \"CNAME\",
    \"name\": \"$HOSTNAME_PART\",
    \"content\": \"$TUNNEL_ID.cfargotunnel.com\",
    \"proxied\": true,
    \"comment\": \"Cloudflare Tunnel for KASM - Fixed to enable IPv4/IPv6 resolution\"
  }")

# Check if update was successful
SUCCESS=$(echo "$UPDATE_RESULT" | grep -o '"success":[^,]*' | cut -d':' -f2)
if [ "$SUCCESS" = "true" ]; then
    echo "✅ DNS record updated successfully!"
    echo ""
    
    # Show updated record details
    echo "📋 Updated record details:"
    echo "$UPDATE_RESULT" | jq -r '.result | "   Type: \(.type), Content: \(.content), Proxied: \(.proxied)"' 2>/dev/null || \
    echo "   CNAME record updated and proxied"
    echo ""
    
    echo "🎉 DNS Fix Complete!"
    echo ""
    echo "📝 What was fixed:"
    echo "   ❌ Before: CNAME record may not have been proxied (gray cloud)"
    echo "   ✅ After:  CNAME record is now proxied (orange cloud)"
    echo ""
    echo "🌐 Expected results:"
    echo "   • $TUNNEL_HOSTNAME will now resolve to both IPv4 and IPv6 addresses"
    echo "   • Traffic will be secured and accelerated by Cloudflare"
    echo "   • DNS_PROBE_FINISHED_NXDOMAIN errors should be resolved"
    echo ""
    echo "⏱️  DNS propagation time: 5-10 minutes globally"
    echo ""
    echo "🧪 Test the fix:"
    echo "   • Wait 5-10 minutes for DNS propagation"
    echo "   • Try accessing: https://$TUNNEL_HOSTNAME"
    echo "   • Check DNS resolution: nslookup $TUNNEL_HOSTNAME"
    
else
    echo "❌ Failed to update DNS record"
    echo "Error details:"
    echo "$UPDATE_RESULT" | jq -r '.errors[]? | "   \(.message)"' 2>/dev/null || \
    echo "$UPDATE_RESULT"
    exit 1
fi

echo ""
echo "✅ DNS fix completed successfully!"