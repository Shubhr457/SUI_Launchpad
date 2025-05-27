'use client';

import { useState } from 'react';
import Link from 'next/link';
import { ProjectCard } from '@/components/ProjectCard';

// Mock data - replace with actual contract calls
const mockProjects = [
  {
    id: '1',
    name: 'SuiSwap',
    symbol: 'SSWAP',
    description: 'A decentralized exchange built on the Sui blockchain with low fees and high throughput.',
    tokenPrice: 0.1,
    totalRaised: 1250000,
    target: 2000000,
    startTime: Date.now() - 3 * 24 * 60 * 60 * 1000, // 3 days ago
    endTime: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days from now
    status: 'live',
    kycRequired: true,
  },
  {
    id: '2',
    name: 'SuiLend',
    symbol: 'SLEND',
    description: 'A decentralized lending protocol on Sui enabling users to earn interest on deposits and borrow assets.',
    tokenPrice: 0.25,
    totalRaised: 3500000,
    target: 5000000,
    startTime: Date.now() + 2 * 24 * 60 * 60 * 1000, // 2 days from now
    endTime: Date.now() + 14 * 24 * 60 * 60 * 1000, // 14 days from now
    status: 'upcoming',
    kycRequired: false,
  },
  {
    id: '3',
    name: 'SuiPunks',
    symbol: 'PUNK',
    description: 'Unique digital collectibles on the Sui blockchain. Each SuiPunk is unique and generated algorithmically.',
    tokenPrice: 50,
    totalRaised: 1000000,
    target: 1000000,
    startTime: Date.now() - 14 * 24 * 60 * 60 * 1000, // 14 days ago
    endTime: Date.now() - 7 * 24 * 60 * 60 * 1000, // 7 days ago
    status: 'ended',
    kycRequired: true,
  },
];

type ProjectStatus = 'all' | 'live' | 'upcoming' | 'ended';

export default function ProjectsPage() {
  const [statusFilter, setStatusFilter] = useState<ProjectStatus>('all');
  
  const filteredProjects = statusFilter === 'all' 
    ? mockProjects 
    : mockProjects.filter(project => project.status === statusFilter);

  return (
    <div className="container py-12">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Launchpad Projects</h1>
          <p className="text-muted-foreground">
            Discover and participate in the latest token launches on Sui
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as ProjectStatus)}
            className="rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
          >
            <option value="all">All Projects</option>
            <option value="live">Live Now</option>
            <option value="upcoming">Upcoming</option>
            <option value="ended">Ended</option>
          </select>
        </div>
      </div>

      {filteredProjects.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredProjects.map((project) => (
            <Link key={project.id} href={`/projects/${project.id}`}>
              <ProjectCard {...project} />
            </Link>
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-12 border rounded-lg bg-muted/50">
          <div className="text-muted-foreground mb-4">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="48"
              height="48"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="h-12 w-12 mx-auto"
            >
              <path d="M21 12a9 9 0 1 1-6.219-8.56" />
              <path d="M3 12a6 6 0 0 0 4 5.67" />
            </svg>
          </div>
          <h3 className="text-lg font-medium mb-1">No projects found</h3>
          <p className="text-sm text-muted-foreground text-center max-w-md">
            There are no {statusFilter === 'all' ? '' : statusFilter} projects at the moment. Please check back later.
          </p>
        </div>
      )}
    </div>
  );
}
