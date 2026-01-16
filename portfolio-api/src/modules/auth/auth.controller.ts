import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  async getMe(@CurrentUser() user: any) {
    return this.authService.getMe(user.id);
  }
}

@Controller('users')
export class UsersController {
  constructor(private authService: AuthService) {}

  @Post('fcm-token')
  @UseGuards(AuthGuard('jwt'))
  async updateFcmToken(
    @CurrentUser() user: any,
    @Body('token') token: string,
  ) {
    return this.authService.updateFcmToken(user.id, token);
  }
}
