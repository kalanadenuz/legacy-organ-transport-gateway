#!/bin/bash
URL="http://127.0.0.1:8000/soap"

run_test() {
  echo -e "\n========================================================"
  echo -e " [TEST $1] $2"
  echo -e "========================================================"
  res=$(curl -s -4 -w "\nHTTP_STATUS:%{http_code}" -X POST "$URL" -H "Content-Type: text/xml; charset=utf-8" -d "$3")
  echo "Status: $(echo "$res" | grep 'HTTP_STATUS:' | cut -d: -f2)"
  body=$(echo "$res" | sed -e 's/HTTP_STATUS:.*//g')
  if command -v xmllint >/dev/null 2>&1; then
    echo "$body" | xmllint --format - 2>/dev/null || echo "$body"
  else
    echo "$body"
  fi
}

# 1. Success Path
run_test "1" "ReserveOrgan (Success -> HTTP 200)" \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://healthcare.org/transport"><soapenv:Body><t:ReserveOrganRequest><t:donorId>DONOR-991</t:donorId><t:organType>HEART</t:organType><t:hospitalId>12</t:hospitalId></t:ReserveOrganRequest></soapenv:Body></soapenv:Envelope>'

# 2. Validation Error
run_test "2" "ReserveOrgan (INVALID_ARGUMENT -> soap:Sender 500)" \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://healthcare.org/transport"><soapenv:Body><t:ReserveOrganRequest><t:donorId>DONOR-991</t:donorId><t:organType>HEART</t:organType><t:hospitalId>-1</t:hospitalId></t:ReserveOrganRequest></soapenv:Body></soapenv:Envelope>'

# 3. Not Found
run_test "3" "ReserveOrgan (NOT_FOUND -> soap:Sender 500)" \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://healthcare.org/transport"><soapenv:Body><t:ReserveOrganRequest><t:donorId>EXPIRED</t:donorId><t:organType>HEART</t:organType><t:hospitalId>12</t:hospitalId></t:ReserveOrganRequest></soapenv:Body></soapenv:Envelope>'

# 4. Status Check
run_test "4" "GetTransportStatus (Success -> HTTP 200)" \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://healthcare.org/transport"><soapenv:Body><t:GetTransportStatusRequest><t:reservationId>RES-100234</t:reservationId></t:GetTransportStatusRequest></soapenv:Body></soapenv:Envelope>'

# 5. Cancel
run_test "5" "CancelReservation (Success -> HTTP 200)" \
'<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:t="http://healthcare.org/transport"><soapenv:Body><t:CancelReservationRequest><t:reservationId>RES-100234</t:reservationId><t:reason>Unstable</t:reason></t:CancelReservationRequest></soapenv:Body></soapenv:Envelope>'
