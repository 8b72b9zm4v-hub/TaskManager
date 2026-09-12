import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {
    return this.prisma.task.findMany({ orderBy: { createdAt: 'desc' } });
  }

  create(createTaskDto: CreateTaskDto) {
    return this.prisma.task.create({ data: createTaskDto });
  }

  async update(id: string, updateTaskDto: UpdateTaskDto) {
    await this.ensureExists(id);
    return this.prisma.task.update({ where: { id }, data: updateTaskDto });
  }

  async remove(id: string) {
    await this.ensureExists(id);
    await this.prisma.task.delete({ where: { id } });
  }

  private async ensureExists(id: string) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (task) {
      throw new NotFoundException(`Task ${id} not found`);
    }
  }
}
