#!/bin/bash

echo "=== 1. Testing ReserveOrgan Success ==="
curl -s -X POST http://localhost:8000/soap \
  -H "Content-Type: text/xml" \
  -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:trans="http://healthcare.org/transport">
       <soapenv:Header/>
       <soapenv:Body>
          <trans:ReserveOrganRequest>
             <donorId>DONOR-991</donorId>
             <organType>HEART</organType>
             <hospitalId>12</hospitalId>
          </trans:ReserveOrganRequest>
       </soapenv:Body>
    </soapenv:Envelope>'

echo -e "\n\n=== 2. Testing Fault Mapping (INVALID_ARGUMENT -> Sender) ==="
curl -s -X POST http://localhost:8000/soap \
  -H "Content-Type: text/xml" \
  -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:trans="http://healthcare.org/transport">
       <soapenv:Header/>
       <soapenv:Body>
          <trans:ReserveOrganRequest>
             <donorId>DONOR-991</donorId>
             <organType>HEART</organType>
             <hospitalId>-1</hospitalId>
          </trans:ReserveOrganRequest>
       </soapenv:Body>
    </soapenv:Envelope>'