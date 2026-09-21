#!/bin/bash

GATEWAY_URL="http://localhost:8000/soap"

print_header() {
    echo -e "\n================================================================================"
    echo -e " TEST: $1"
    echo -e "================================================================================"
}

execute_test() {
    local payload="$1"
    
    # Send request, output body, and append HTTP status code
    response=$(curl -s -w "\nHTTP_STATUS_CODE:%{http_code}" -X POST "$GATEWAY_URL" \
        -H "Content-Type: text/xml; charset=utf-8" \
        -d "$payload")

    body=$(echo "$response" | sed -e 's/HTTP_STATUS_CODE\:.*//g')
    status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTP_STATUS_CODE://')

    echo "Response Status Code: $status"
    echo "Response Payload:"
    # Use xmllint if available for pretty-printing, otherwise fall back to raw output
    if command -v xmllint > /dev/null 2>&1; then
        echo "$body" | xmllint --format -
    else
        echo "$body"
    fi
}

# --- TEST 1: ReserveOrgan (Success) ---
print_header "1. ReserveOrgan - Successful Dispatch (Expects HTTP 200)"
execute_test '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:trans="http://healthcare.org/transport">
   <soapenv:Header/>
   <soapenv:Body>
      <trans:ReserveOrganRequest>
         <donorId>DONOR-991</donorId>
         <organType>HEART</organType>
         <hospitalId>12</hospitalId>
      </trans:ReserveOrganRequest>
   </soapenv:Body>
</soapenv:Envelope>'

# --- TEST 2: ReserveOrgan (Validation Error -> Fault) ---
print_header "2. ReserveOrgan - INVALID_ARGUMENT Mapping (Expects HTTP 500 / soap:Sender)"
execute_test '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:trans="http://healthcare.org/transport">
   <soapenv:Header/>
   <soapenv:Body>
      <trans:ReserveOrganRequest>
         <donorId>DONOR-991</donorId>
         <organType>HEART</organType>
         <hospitalId>-1</hospitalId>
      </trans:ReserveOrganRequest>
   </soapenv:Body>
</soapenv:Envelope>'

# --- TEST 3: ReserveOrgan (Record Not Found -> Fault) ---
print_header "3. ReserveOrgan - NOT_FOUND Mapping (Expects HTTP 500 / soap:Sender)"
execute_test '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:trans="http://healthcare.org/transport">
   <soapenv:Header/>
   <soapenv:Body>
      <trans:ReserveOrganRequest>
         <donorId>EXPIRED</donorId>
         <organType>HEART</organType>
         <hospitalId>12</hospitalId>
      </trans:ReserveOrganRequest>
   </soapenv:Body>
</soapenv:Envelope>'

# --- TEST 4: GetTransportStatus (Success) ---
print_header "4. GetTransportStatus - Active Tracking (Expects HTTP 200)"
execute_test '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:trans="http://healthcare.org/transport">
   <soapenv:Header/>
   <soapenv:Body>
      <trans:GetTransportStatusRequest>
         <reservationId>RES-100234</reservationId>
      </trans:GetTransportStatusRequest>
   </soapenv:Body>
</soapenv:Envelope>'

# --- TEST 5: CancelReservation (Success) ---
print_header "5. CancelReservation - Operation Abort (Expects HTTP 200)"
execute_test '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:trans="http://healthcare.org/transport">
   <soapenv:Header/>
   <soapenv:Body>
      <trans:CancelReservationRequest>
         <reservationId>RES-100234</reservationId>
         <reason>Recipient condition unstable</reason>
      </trans:CancelReservationRequest>
   </soapenv:Body>
</soapenv:Envelope>'

echo -e "\n================================================================================"
echo -e " ALL TESTS COMPLETED"
echo -e "================================================================================\n"