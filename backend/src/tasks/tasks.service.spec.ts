import { NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TasksService } from './tasks.service';

describe('TasksService', () => {
  const prisma = {
    task: {
      create: jest.fn(),
      delete: jest.fn(),
      findAll: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  };

  let service: TasksService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new TasksService(prisma as unknown as PrismaService);
  });

  it('creates a task from the received DTO', async () => {
    const dto = { title: 'Préparer la CI' };
    const createdTask = { id: 'task-1', ...dto };
    prisma.task.create.mockResolvedValue(createdTask);

    await expect(service.create(dto)).resolves.toEqual(createdTask);
    expect(prisma.task.create).toHaveBeenCalledWith({ data: dto });
  });

  it('rejects an update when the task does not exist', async () => {
    prisma.task.findUnique.mockResolvedValue(null);

    await expect(
      service.update('missing-task', { status: 'DONE' }),
    ).rejects.toThrow(
      new NotFoundException('Task missing-task not found'),
    );
    expect(prisma.task.update).not.toHaveBeenCalled();
  });

  it('deletes an existing task', async () => {
    const task = { id: 'task-1', title: 'Supprimer cette tâche' };
    prisma.task.findUnique.mockResolvedValue(task);
    prisma.task.delete.mockResolvedValue(task);

    await expect(service.remove(task.id)).resolves.toBeUndefined();
    expect(prisma.task.findUnique).toHaveBeenCalledWith({
      where: { id: task.id },
    });
    expect(prisma.task.delete).toHaveBeenCalledWith({
      where: { id: task.id },
    });
  });
});
