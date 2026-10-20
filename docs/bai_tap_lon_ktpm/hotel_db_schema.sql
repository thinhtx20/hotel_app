-- CreateEnum
CREATE TYPE "Role" AS ENUM ('ADMIN', 'RECEPTIONIST', 'CUSTOMER');

-- CreateEnum
CREATE TYPE "RoomStatus" AS ENUM ('AVAILABLE', 'OCCUPIED', 'RESERVED', 'CLEANING', 'MAINTENANCE', 'PENDING_APPROVAL', 'REJECTED');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED');

-- CreateEnum
CREATE TYPE "PaymentMethod" AS ENUM ('CASH', 'CREDIT_CARD', 'BANK_TRANSFER');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('UNPAID', 'PARTIAL', 'PAID', 'REFUNDED');

-- CreateEnum
CREATE TYPE "PaymentEntryType" AS ENUM ('PAYMENT', 'DEPOSIT', 'REFUND');

-- CreateEnum
CREATE TYPE "PaymentEntryStatus" AS ENUM ('PENDING', 'CONFIRMED', 'REJECTED');

-- CreateEnum
CREATE TYPE "ShiftType" AS ENUM ('MORNING', 'AFTERNOON', 'NIGHT', 'CUSTOM');

-- CreateEnum
CREATE TYPE "ShiftStatus" AS ENUM ('OPEN', 'CLOSED');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "phone" TEXT,
    "avatar" TEXT,
    "role" "Role" NOT NULL DEFAULT 'CUSTOMER',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "activeSessionId" TEXT,
    "activeDevice" TEXT,
    "fcmToken" TEXT,
    "lastLoginAt" TIMESTAMP(3),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "room_types" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,
    "basePrice" DOUBLE PRECISION NOT NULL,
    "capacityAdults" INTEGER NOT NULL DEFAULT 2,
    "capacityChildren" INTEGER NOT NULL DEFAULT 1,
    "sizeSqM" DOUBLE PRECISION,
    "amenities" TEXT[],
    "images" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "room_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rooms" (
    "id" TEXT NOT NULL,
    "roomNumber" TEXT NOT NULL,
    "floor" INTEGER NOT NULL,
    "roomTypeId" TEXT NOT NULL,
    "status" "RoomStatus" NOT NULL DEFAULT 'AVAILABLE',
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rooms_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bookings" (
    "id" TEXT NOT NULL,
    "bookingCode" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "roomId" TEXT NOT NULL,
    "checkInDate" TIMESTAMP(3) NOT NULL,
    "checkOutDate" TIMESTAMP(3) NOT NULL,
    "actualCheckIn" TIMESTAMP(3),
    "actualCheckOut" TIMESTAMP(3),
    "guestCount" INTEGER NOT NULL DEFAULT 1,
    "totalAmount" DOUBLE PRECISION NOT NULL,
    "depositAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "status" "BookingStatus" NOT NULL DEFAULT 'PENDING',
    "specialRequests" TEXT,
    "confirmedAt" TIMESTAMP(3),
    "confirmedById" TEXT,
    "confirmationNote" TEXT,
    "cancellationReason" TEXT,
    "cancelledAt" TIMESTAMP(3),
    "cancelledById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "bookings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "id" TEXT NOT NULL,
    "invoiceCode" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "roomAmount" DOUBLE PRECISION NOT NULL,
    "servicesAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "discount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "tax" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "finalAmount" DOUBLE PRECISION NOT NULL,
    "paidAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "paymentMethod" "PaymentMethod" NOT NULL DEFAULT 'CASH',
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'UNPAID',
    "issuedById" TEXT,
    "notes" TEXT,
    "paidAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" TEXT NOT NULL,
    "invoiceId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "method" "PaymentMethod" NOT NULL DEFAULT 'CASH',
    "type" "PaymentEntryType" NOT NULL DEFAULT 'PAYMENT',
    "status" "PaymentEntryStatus" NOT NULL DEFAULT 'CONFIRMED',
    "reference" TEXT,
    "note" TEXT,
    "createdById" TEXT,
    "confirmedById" TEXT,
    "confirmedAt" TIMESTAMP(3),
    "rejectedReason" TEXT,
    "shiftId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "extra_service_orders" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "serviceName" TEXT NOT NULL,
    "unitPrice" DOUBLE PRECISION NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "totalPrice" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'CONFIRMED',
    "requestedById" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "extra_service_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "hotel_services" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "description" TEXT,
    "unitPrice" DOUBLE PRECISION NOT NULL,
    "unit" TEXT NOT NULL DEFAULT 'lần',
    "icon" TEXT,
    "isAvailable" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "hotel_services_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "password_resets" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "otp" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "used" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "password_resets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "work_shifts" (
    "id" TEXT NOT NULL,
    "shiftCode" TEXT NOT NULL,
    "staffId" TEXT NOT NULL,
    "shiftType" "ShiftType" NOT NULL DEFAULT 'MORNING',
    "deskName" TEXT,
    "status" "ShiftStatus" NOT NULL DEFAULT 'OPEN',
    "startTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endTime" TIMESTAMP(3),
    "initialCash" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "actualCash" DOUBLE PRECISION,
    "expectedCash" DOUBLE PRECISION,
    "cashDifference" DOUBLE PRECISION,
    "creditCardAmount" DOUBLE PRECISION DEFAULT 0,
    "bankTransferAmount" DOUBLE PRECISION DEFAULT 0,
    "totalRevenue" DOUBLE PRECISION DEFAULT 0,
    "openNote" TEXT,
    "closeNote" TEXT,
    "differenceReason" TEXT,
    "handoverStaffId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "work_shifts_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_role_idx" ON "users"("role");

-- CreateIndex
CREATE INDEX "users_isActive_idx" ON "users"("isActive");

-- CreateIndex
CREATE UNIQUE INDEX "room_types_name_key" ON "room_types"("name");

-- CreateIndex
CREATE UNIQUE INDEX "room_types_code_key" ON "room_types"("code");

-- CreateIndex
CREATE UNIQUE INDEX "rooms_roomNumber_key" ON "rooms"("roomNumber");

-- CreateIndex
CREATE INDEX "rooms_status_idx" ON "rooms"("status");

-- CreateIndex
CREATE INDEX "rooms_floor_idx" ON "rooms"("floor");

-- CreateIndex
CREATE INDEX "rooms_roomTypeId_idx" ON "rooms"("roomTypeId");

-- CreateIndex
CREATE UNIQUE INDEX "bookings_bookingCode_key" ON "bookings"("bookingCode");

-- CreateIndex
CREATE INDEX "bookings_status_idx" ON "bookings"("status");

-- CreateIndex
CREATE INDEX "bookings_checkInDate_idx" ON "bookings"("checkInDate");

-- CreateIndex
CREATE INDEX "bookings_checkOutDate_idx" ON "bookings"("checkOutDate");

-- CreateIndex
CREATE INDEX "bookings_roomId_idx" ON "bookings"("roomId");

-- CreateIndex
CREATE INDEX "bookings_customerId_idx" ON "bookings"("customerId");

-- CreateIndex
CREATE INDEX "bookings_createdAt_idx" ON "bookings"("createdAt");

-- CreateIndex
CREATE INDEX "bookings_roomId_status_idx" ON "bookings"("roomId", "status");

-- CreateIndex
CREATE INDEX "bookings_customerId_status_idx" ON "bookings"("customerId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_invoiceCode_key" ON "invoices"("invoiceCode");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_bookingId_key" ON "invoices"("bookingId");

-- CreateIndex
CREATE INDEX "invoices_paymentStatus_idx" ON "invoices"("paymentStatus");

-- CreateIndex
CREATE INDEX "invoices_paidAt_idx" ON "invoices"("paidAt");

-- CreateIndex
CREATE INDEX "invoices_issuedById_idx" ON "invoices"("issuedById");

-- CreateIndex
CREATE INDEX "invoices_createdAt_idx" ON "invoices"("createdAt");

-- CreateIndex
CREATE INDEX "payments_invoiceId_idx" ON "payments"("invoiceId");

-- CreateIndex
CREATE INDEX "payments_status_idx" ON "payments"("status");

-- CreateIndex
CREATE INDEX "payments_confirmedAt_idx" ON "payments"("confirmedAt");

-- CreateIndex
CREATE INDEX "payments_shiftId_idx" ON "payments"("shiftId");

-- CreateIndex
CREATE INDEX "payments_confirmedById_idx" ON "payments"("confirmedById");

-- CreateIndex
CREATE INDEX "payments_confirmedById_status_confirmedAt_idx" ON "payments"("confirmedById", "status", "confirmedAt");

-- CreateIndex
CREATE INDEX "extra_service_orders_bookingId_idx" ON "extra_service_orders"("bookingId");

-- CreateIndex
CREATE INDEX "extra_service_orders_status_idx" ON "extra_service_orders"("status");

-- CreateIndex
CREATE UNIQUE INDEX "hotel_services_code_key" ON "hotel_services"("code");

-- CreateIndex
CREATE UNIQUE INDEX "password_resets_token_key" ON "password_resets"("token");

-- CreateIndex
CREATE INDEX "password_resets_email_idx" ON "password_resets"("email");

-- CreateIndex
CREATE UNIQUE INDEX "work_shifts_shiftCode_key" ON "work_shifts"("shiftCode");

-- CreateIndex
CREATE INDEX "work_shifts_staffId_idx" ON "work_shifts"("staffId");

-- CreateIndex
CREATE INDEX "work_shifts_status_idx" ON "work_shifts"("status");

-- CreateIndex
CREATE INDEX "work_shifts_startTime_idx" ON "work_shifts"("startTime");

-- AddForeignKey
ALTER TABLE "rooms" ADD CONSTRAINT "rooms_roomTypeId_fkey" FOREIGN KEY ("roomTypeId") REFERENCES "room_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "rooms"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_confirmedById_fkey" FOREIGN KEY ("confirmedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bookings" ADD CONSTRAINT "bookings_cancelledById_fkey" FOREIGN KEY ("cancelledById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_issuedById_fkey" FOREIGN KEY ("issuedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "invoices"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_confirmedById_fkey" FOREIGN KEY ("confirmedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "work_shifts"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "extra_service_orders" ADD CONSTRAINT "extra_service_orders_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "bookings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "extra_service_orders" ADD CONSTRAINT "extra_service_orders_requestedById_fkey" FOREIGN KEY ("requestedById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_shifts" ADD CONSTRAINT "work_shifts_staffId_fkey" FOREIGN KEY ("staffId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_shifts" ADD CONSTRAINT "work_shifts_handoverStaffId_fkey" FOREIGN KEY ("handoverStaffId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

