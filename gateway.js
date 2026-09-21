const express = require('express');
const soap = require('soap');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const fs = require('fs');

const packageDefinition = protoLoader.loadSync('organ_transport.proto', {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});
const proto = grpc.loadPackageDefinition(packageDefinition).organ_transport;

// Use 127.0.0.1 for local host resolution to avoid IPv6 issues
const GRPC_HOST = process.env.GRPC_HOST || '127.0.0.1:50051';
const grpcClient = new proto.OrganTransportService(GRPC_HOST, grpc.credentials.createInsecure());

function formatSoapFault(err, res) {
  let faultCode = "Receiver";
  if (err.code === grpc.status.INVALID_ARGUMENT || err.code === grpc.status.NOT_FOUND) {
    faultCode = "Sender";
  }

  // Set HTTP status code to 500 for SOAP Fault
  if (res && typeof res.status === 'function') {
    res.status(500);
  }

  return {
    Fault: {
      faultcode: faultCode,
      faultstring: err.details || "Internal error occurred",
      detail: { grpcCode: err.code }
    }
  };
}

const soapService = {
  OrganTransportSOAPService: {
    OrganTransportPort: {
      ReserveOrgan: function(args, callback, headers, req, res) {
        const grpcPayload = {
          donor_id: args.donorId || '',
          organ_type: args.organType || '',
          hospital_id: parseInt(args.hospitalId, 10) || 0
        };

        const deadline = new Date(Date.now() + 5000);

        grpcClient.ReserveOrgan(grpcPayload, { deadline }, (err, response) => {
          if (err) return callback(formatSoapFault(err, res));
          return callback(null, {
            reservationId: response.reservation_id,
            status: response.status,
            viabilityMinutes: response.viability_minutes
          });
        });
      },

      GetTransportStatus: function(args, callback, headers, req, res) {
        const deadline = new Date(Date.now() + 5000);
        grpcClient.GetTransportStatus({ reservation_id: args.reservationId || '' }, { deadline }, (err, response) => {
          if (err) return callback(formatSoapFault(err, res));
          return callback(null, {
            reservationId: response.reservation_id,
            currentLocation: response.current_location,
            etaMinutes: response.eta_minutes
          });
        });
      },

      CancelReservation: function(args, callback, headers, req, res) {
        const deadline = new Date(Date.now() + 5000);
        grpcClient.CancelReservation({
          reservation_id: args.reservationId || '',
          reason: args.reason || ''
        }, { deadline }, (err, response) => {
          if (err) return callback(formatSoapFault(err, res));
          return callback(null, {
            success: response.success,
            message: response.message
          });
        });
      }
    }
  }
};

const xml = fs.readFileSync('organ_transport.wsdl', 'utf8');
const app = express();
app.use(express.raw({ type: () => true, limit: '5mb' }));

app.listen(8000, '0.0.0.0', function() {
  soap.listen(app, '/soap', soapService, xml);
  console.log(">>> SOAP Gateway listening on http://0.0.0.0:8000/soap <<<");
});