import { prisma } from '../config/database.js';
import { AuthenticatedUser } from '../middleware/auth.middleware.js';

export class ProfileService {
  public static async getProfile(user: AuthenticatedUser) {
    return {
      id: Number(user.id),
      name: user.name,
      email: user.email,
      role: user.role || 'USER',
    };
  }

  public static async getDeviceTelemetry(user: AuthenticatedUser) {
    const latestLoc = await prisma.location.findFirst({
      where: { userId: user.id },
      orderBy: { updatedAt: 'desc' },
    });

    const latestDevice = await prisma.deviceStatus.findUnique({
      where: { userId: user.id },
    });

    const latitude = latestLoc ? latestLoc.latitude : 28.6139;
    const longitude = latestLoc ? latestLoc.longitude : 77.2090;
    const address = latestLoc?.address || `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
    const batteryLevel = latestDevice ? latestDevice.batteryLevel : 95;

    return {
      deviceModel: 'Android',
      batteryLevel,
      latitude,
      longitude,
      speedKmH: 120.5,
      altitudeMeters: 0.0,
      currentAddress: address,
      satellitesConnected: 18,
    };
  }

  public static async getUserSettings(user: AuthenticatedUser) {
    let settings = await prisma.userSettings.findUnique({
      where: { userId: user.id },
    });

    if (!settings) {
      settings = await prisma.userSettings.create({
        data: {
          userId: user.id,
          locationSharing: true,
          highPrecisionGps: true,
          darkThemeMode: false,
          autoPlayPtt: true,
          stealthMode: false,
        },
      });
    }

    return {
      locationSharing: settings.locationSharing,
      highPrecisionGps: settings.highPrecisionGps,
      darkThemeMode: settings.darkThemeMode,
      autoPlayPtt: settings.autoPlayPtt,
      stealthMode: settings.stealthMode,
    };
  }

  public static async updateUserSettings(user: AuthenticatedUser, dto: any) {
    const updated = await prisma.userSettings.upsert({
      where: { userId: user.id },
      create: {
        userId: user.id,
        locationSharing: dto.locationSharing ?? true,
        highPrecisionGps: dto.highPrecisionGps ?? true,
        darkThemeMode: dto.darkThemeMode ?? false,
        autoPlayPtt: dto.autoPlayPtt ?? true,
        stealthMode: dto.stealthMode ?? false,
      },
      update: {
        ...(dto.locationSharing !== undefined && { locationSharing: dto.locationSharing }),
        ...(dto.highPrecisionGps !== undefined && { highPrecisionGps: dto.highPrecisionGps }),
        ...(dto.darkThemeMode !== undefined && { darkThemeMode: dto.darkThemeMode }),
        ...(dto.autoPlayPtt !== undefined && { autoPlayPtt: dto.autoPlayPtt }),
        ...(dto.stealthMode !== undefined && { stealthMode: dto.stealthMode }),
      },
    });

    return {
      locationSharing: updated.locationSharing,
      highPrecisionGps: updated.highPrecisionGps,
      darkThemeMode: updated.darkThemeMode,
      autoPlayPtt: updated.autoPlayPtt,
      stealthMode: updated.stealthMode,
    };
  }
}
