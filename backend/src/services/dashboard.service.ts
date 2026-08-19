import { prisma } from '../config/database.js';
import { AuthenticatedUser } from '../middleware/auth.middleware.js';

export class DashboardService {
  public static async getDashboard(user: AuthenticatedUser) {
    const userDto = {
      id: Number(user.id),
      name: user.name,
      email: user.email,
      role: user.role,
    };

    const latestLoc = await prisma.location.findFirst({
      where: { userId: user.id },
      orderBy: { updatedAt: 'desc' },
    });

    const locationDto = latestLoc
      ? {
          latitude: latestLoc.latitude,
          longitude: latestLoc.longitude,
          address: latestLoc.address,
          updatedAt: latestLoc.updatedAt.toISOString().slice(0, 19),
        }
      : null;

    const latestDevice = await prisma.deviceStatus.findUnique({
      where: { userId: user.id },
    });

    const deviceStatusDto = latestDevice
      ? {
          online: latestDevice.online,
          isBroadcasting: latestDevice.isBroadcasting,
          batteryLevel: latestDevice.batteryLevel,
          statusMessage: latestDevice.statusMessage,
          updatedAt: latestDevice.updatedAt.toISOString().slice(0, 19),
        }
      : null;

    const activities = await prisma.activity.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
    });

    const activityDtos = activities.map((act) => ({
      id: Number(act.id),
      title: act.title,
      details: act.details,
      type: act.type,
      latitude: act.latitude,
      longitude: act.longitude,
      createdAt: act.createdAt ? act.createdAt.toISOString().slice(0, 19) : null,
    }));

    return {
      user: userDto,
      location: locationDto,
      deviceStatus: deviceStatusDto,
      recentActivities: activityDtos,
    };
  }

  public static async updateLocation(user: AuthenticatedUser, request: { latitude: number; longitude: number; address?: string }) {
    const now = new Date();
    const address = request.address && request.address.trim().length > 0
      ? request.address
      : `${request.latitude.toFixed(4)}, ${request.longitude.toFixed(4)}`;

    const savedLocation = await prisma.location.create({
      data: {
        userId: user.id,
        latitude: request.latitude,
        longitude: request.longitude,
        address,
        updatedAt: now,
      },
    });

    await prisma.activity.create({
      data: {
        userId: user.id,
        title: 'Live GPS Sync',
        details: `Coordinates updated to ${request.latitude.toFixed(4)}, ${request.longitude.toFixed(4)}`,
        type: 'LOCATION_UPDATE',
        latitude: request.latitude,
        longitude: request.longitude,
        createdAt: now,
      },
    });

    return {
      latitude: savedLocation.latitude,
      longitude: savedLocation.longitude,
      address: savedLocation.address,
      updatedAt: savedLocation.updatedAt.toISOString().slice(0, 19),
    };
  }

  public static async updateDeviceStatus(
    user: AuthenticatedUser,
    request: { batteryLevel?: number; online?: boolean; isBroadcasting?: boolean; statusMessage?: string }
  ) {
    const now = new Date();

    const existingStatus = await prisma.deviceStatus.findUnique({
      where: { userId: user.id },
    });

    const online = request.online !== undefined ? request.online : (existingStatus?.online ?? true);
    const isBroadcasting = request.isBroadcasting !== undefined ? request.isBroadcasting : (existingStatus?.isBroadcasting ?? true);
    const batteryLevel = request.batteryLevel !== undefined ? request.batteryLevel : (existingStatus?.batteryLevel ?? 100);

    let statusMessage = request.statusMessage;
    if (!statusMessage || statusMessage.trim().length === 0) {
      statusMessage = online ? (isBroadcasting ? 'Active & Broadcast Mode On' : 'Active (Broadcasting Off)') : 'Offline';
    }

    const savedStatus = await prisma.deviceStatus.upsert({
      where: { userId: user.id },
      create: {
        userId: user.id,
        online,
        isBroadcasting,
        batteryLevel,
        statusMessage,
        updatedAt: now,
      },
      update: {
        online,
        isBroadcasting,
        batteryLevel,
        statusMessage,
        updatedAt: now,
      },
    });

    await prisma.activity.create({
      data: {
        userId: user.id,
        title: 'Device Status Updated',
        details: `Battery: ${savedStatus.batteryLevel}%, Status: ${savedStatus.online ? 'Online' : 'Offline'}`,
        type: 'STATUS_CHANGE',
        latitude: null,
        longitude: null,
        createdAt: now,
      },
    });

    return {
      online: savedStatus.online,
      isBroadcasting: savedStatus.isBroadcasting,
      batteryLevel: savedStatus.batteryLevel,
      statusMessage: savedStatus.statusMessage,
      updatedAt: savedStatus.updatedAt.toISOString().slice(0, 19),
    };
  }
}
