import Link from 'next/link';
import { formatDate, formatCurrency } from '@/lib/utils';

interface ProjectCardProps {
  id: string;
  name: string;
  symbol: string;
  description: string;
  tokenPrice: number;
  totalRaised: number;
  target: number;
  startTime: number;
  endTime: number;
  status: 'upcoming' | 'live' | 'ended';
  kycRequired?: boolean;
  imageUrl?: string;
}

export function ProjectCard({
  id,
  name,
  symbol,
  description,
  tokenPrice,
  totalRaised,
  target,
  startTime,
  endTime,
  status,
  imageUrl = '/placeholder-project.jpg',
}: ProjectCardProps) {
  const progress = Math.min((totalRaised / target) * 100, 100);
  
  return (
    <div className="rounded-lg border bg-card text-card-foreground shadow-sm overflow-hidden">
      <div className="aspect-video bg-muted relative overflow-hidden">
        <img
          src={imageUrl}
          alt={name}
          className="w-full h-full object-cover"
        />
        <div className="absolute bottom-2 right-2 bg-background/80 px-2 py-1 rounded-md text-xs font-medium">
          {status.toUpperCase()}
        </div>
      </div>
      
      <div className="p-4">
        <div className="flex justify-between items-start mb-2">
          <h3 className="font-semibold text-lg">{name} ({symbol})</h3>
          <span className="text-sm text-muted-foreground">
            {formatCurrency(tokenPrice)} / token
          </span>
        </div>
        
        <p className="text-sm text-muted-foreground line-clamp-2 mb-4">
          {description}
        </p>
        
        <div className="space-y-2 mb-4">
          <div className="flex justify-between text-sm">
            <span>Progress</span>
            <span>{progress.toFixed(1)}%</span>
          </div>
          <div className="h-2 bg-muted rounded-full overflow-hidden">
            <div 
              className="h-full bg-primary" 
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="flex justify-between text-sm">
            <span>{formatCurrency(totalRaised)} raised</span>
            <span>Target: {formatCurrency(target)}</span>
          </div>
        </div>
        
        <div className="grid grid-cols-2 gap-2 text-sm mb-4">
          <div>
            <div className="text-muted-foreground">Start</div>
            <div>{formatDate(startTime)}</div>
          </div>
          <div className="text-right">
            <div className="text-muted-foreground">End</div>
            <div>{formatDate(endTime)}</div>
          </div>
        </div>
        
        <Link
          href={`/projects/${id}`}
          className="w-full inline-flex items-center justify-center rounded-md bg-primary text-primary-foreground px-4 py-2 text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          {status === 'upcoming' ? 'View Details' : status === 'live' ? 'Participate Now' : 'View Results'}
        </Link>
      </div>
    </div>
  );
}
