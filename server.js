const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const packageDefinition = protoLoader.loadSync('organ_transport.proto', {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});
const proto = grpc.loadPackageDefinition(packageDefinition).organ_transport;

function reserveOrgan(call, callback) {
  const { donor_id, organ_type, hospital_id } = call.request;

  if (!donor_id || !organ_type) {
    return callback({
      code: grpc.status.INVALID_ARGUMENT,
      details: "Missing required fields: donor_id or organ_type"
    });
  }

  if (hospital_id <= 0) {
    return callback({
      code: grpc.status.INVALID_ARGUMENT,
      details: "Hospital ID must be a positive integer"
    });
  }

  if (donor_id === "EXPIRED") {
    return callback({
      code: grpc.status.NOT_FOUND,
      details: "Donor record expired or invalid"
    });
  }

  callback(null, {
    reservation_id: `RES-${Date.now()}`,
    status: "DISPATCHED",
    viability_minutes: (organ_type || "").toUpperCase() === "HEART" ? 240 : 720
  });
}

function getTransportStatus(call, callback) {
  if (!call.request.reservation_id) {
    return callback({
      code: grpc.status.INVALID_ARGUMENT,
      details: "Reservation ID is required"
    });
  }
  callback(null, {
    reservation_id: call.request.reservation_id,
    current_location: "In-Transit (Flight 102)",
    eta_minutes: 45
  });
}

function cancelReservation(call, callback) {
  if (!call.request.reservation_id) {
    return callback({
      code: grpc.status.INVALID_ARGUMENT,
      details: "Reservation ID is required"
    });
  }
  callback(null, {
    success: true,
    message: "Reservation successfully cancelled"
  });
}

function main() {
  const server = new grpc.Server();
  server.addService(proto.OrganTransportService.service, {
    ReserveOrgan: reserveOrgan,
    GetTransportStatus: getTransportStatus,
    CancelReservation: cancelReservation
  });

  server.bindAsync('0.0.0.0:50051', grpc.ServerCredentials.createInsecure(), (err, port) => {
    if (err) {
      console.error("Failed to bind gRPC server:", err);
      process.exit(1);
    }
    console.log(`>>> gRPC Server running successfully on port ${port} <<<`);
  });
}

main();